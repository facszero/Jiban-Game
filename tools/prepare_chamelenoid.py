"""Rebuild the game asset from the preserved sculpt; run with Blender 4.3.2."""
import bpy, math, os, json, sys, argparse
from mathutils import Vector, Quaternion
from mathutils.noise import noise_vector
parser=argparse.ArgumentParser()
parser.add_argument('--source',required=True,help='Path to the preserved static Blender sculpt')
parser.add_argument('--output',required=True,help='Directory for the GLB and report')
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
BASE=os.path.dirname(os.path.abspath(args.source))
OUT=os.path.abspath(args.output)
os.makedirs(OUT,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=os.path.abspath(args.source))
for o in list(bpy.data.objects):
    if o.get('asset_role')!='character': bpy.data.objects.remove(o,do_unlink=True)

def clamp(x): return max(0,min(1,x))
def smooth(a,b,x):
    t=clamp((x-a)/(b-a));return t*t*(3-2*t)
def shape(p):
    x,y,z=p
    core=1-smooth(.30,.45,abs(x))
    chest=smooth(1.20,1.65,z)*(1-smooth(1.95,2.13,z))*core
    y*=1+.48*chest
    y-=.085*smooth(1.93,2.23,z)
    return Vector((x,y,z))

meshes=[]
for o in list(bpy.context.scene.objects):
    bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
    bpy.ops.object.convert(target='MESH')
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    for v in o.data.vertices: v.co=shape(v.co)
    # Preserve the silhouette while reducing the high-density sculpt for runtime.
    if len(o.data.polygons)>120:
        dec=o.modifiers.new('Game reduction','DECIMATE')
        dec.ratio=.07 if o.name.startswith('Sculpted') else .12
        bpy.ops.object.modifier_apply(modifier=dec.name)
    meshes.append(o)

# Bake deterministic tonal variation into vertex colors; no Blender-only shaders.
colors={}
for mat in bpy.data.materials:
    if not mat.use_nodes: continue
    ramp=next((n for n in mat.node_tree.nodes if n.type=='VALTORGB'),None)
    colors[mat.name]=tuple(ramp.color_ramp.elements[-1].color[:3]) if ramp else (.14,.19,.085)
    bs=mat.node_tree.nodes.get('Principled BSDF')
    if not bs: continue
    mat.node_tree.nodes.clear()
    bs=mat.node_tree.nodes.new('ShaderNodeBsdfPrincipled')
    bs.inputs['Roughness'].default_value=.62
    attr=mat.node_tree.nodes.new('ShaderNodeVertexColor');attr.layer_name='Color'
    output=mat.node_tree.nodes.new('ShaderNodeOutputMaterial')
    mat.node_tree.links.new(attr.outputs['Color'],bs.inputs['Base Color'])
    mat.node_tree.links.new(bs.outputs[0],output.inputs[0])
for o in meshes:
    col=o.data.color_attributes.new(name='Color',type='BYTE_COLOR',domain='CORNER')
    for poly in o.data.polygons:
        base=colors.get(o.data.materials[poly.material_index].name,(.14,.19,.085))
        for li in poly.loop_indices:
            p=o.data.vertices[o.data.loops[li].vertex_index].co
            n=.72+.22*noise_vector(p*55).x
            col.data[li].color=(*(v*n for v in base),1)

bpy.ops.object.select_all(action='DESELECT')
rigdata=bpy.data.armatures.new('ChamelenoidSkeleton')
rig=bpy.data.objects.new('ChamelenoidRig',rigdata);bpy.context.collection.objects.link(rig)
rig.select_set(True);bpy.context.view_layer.objects.active=rig;bpy.ops.object.mode_set(mode='EDIT')
def bone(name,a,b,parent=None):
    q=rigdata.edit_bones.new(name);q.head=shape(Vector(a));q.tail=shape(Vector(b))
    if parent:q.parent=rigdata.edit_bones[parent]
    return q
bone('pelvis',(0,.035,1.17),(0,.03,1.40))
bone('chest',(0,.03,1.40),(0,.035,2.02),'pelvis')
bone('head',(0,.035,2.02),(0,.012,2.50),'chest')
bone('jaw',(0,-.01,2.19),(0,-.11,2.10),'head')
for s,side in [(-1,'L'),(1,'R')]:
    bone('upper_arm.'+side,(s*.43,.005,1.91),(s*.53,-.025,1.53),'chest')
    bone('forearm.'+side,(s*.53,-.025,1.53),(s*.61,-.07,1.19),'upper_arm.'+side)
    bone('hand.'+side,(s*.61,-.07,1.19),(s*.63,-.075,1.00),'forearm.'+side)
    bone('thigh.'+side,(s*.20,.035,1.19),(s*.27,-.07,.71),'pelvis')
    bone('shin.'+side,(s*.27,-.07,.71),(s*.30,.015,.17),'thigh.'+side)
    bone('foot.'+side,(s*.30,.015,.17),(s*.30,-.25,.075),'shin.'+side)
bpy.ops.object.mode_set(mode='OBJECT')

def blend(a,b,w):return {a:1-w,b:w}
def weights(p,name):
    x,y,z=p;side='L' if x<0 else 'R'; ax=abs(x)
    if name.startswith(('Lower jaw','Chin','Mouth seam')):return {'jaw':1}
    if z>2.03 and ax<.30:return {'head':1}
    if name.startswith(('Shoulder mantle','Overlapping shoulder')):return {'upper_arm.'+side:1}
    if name.startswith(('Bracer','Palm','Curved finger','Finger claw','Opposed thumb')):
        return {('forearm.' if name.startswith('Bracer') else 'hand.')+side:1}
    if name.startswith(('Kneecap','Shin armor')):return {'shin.'+side:1}
    if name.startswith(('Instep','Toe')):return {'foot.'+side:1}
    # Region gates stop the nearby hands/forearms from capturing hip vertices.
    boundary=.34+.18*clamp((1.8-z)/.8)
    width=.005+.075*smooth(1.4,1.8,z)
    if ax>boundary-width and z>.90:
        if z>1.36:
            w=blend('forearm.'+side,'upper_arm.'+side,smooth(1.44,1.62,z))
            arm=smooth(boundary-width,boundary+width,ax)
            w={k:v*arm for k,v in w.items()};w['chest']=1-arm
            return w
        return blend('hand.'+side,'forearm.'+side,smooth(1.12,1.25,z))
    if z<1.19 and z>.88 and ax<.10:
        pelvis=smooth(1.02,1.20,z);right=smooth(-.10,.10,x)
        return {'pelvis':pelvis,'thigh.L':(1-pelvis)*(1-right),'thigh.R':(1-pelvis)*right}
    if z<1.19:
        if z<.27:return blend('foot.'+side,'shin.'+side,smooth(.13,.25,z))
        if z<.88:return blend('shin.'+side,'thigh.'+side,smooth(.62,.83,z))
        return blend('thigh.'+side,'pelvis',smooth(1.02,1.20,z))
    if z>1.94:return blend('chest','head',smooth(1.94,2.12,z))
    return blend('pelvis','chest',smooth(1.25,1.53,z))

for o in meshes:
    groups={b.name:o.vertex_groups.new(name=b.name) for b in rigdata.bones}
    center=sum((v.co for v in o.data.vertices),Vector())/max(1,len(o.data.vertices))
    for v in o.data.vertices:
        # Plates and facial details remain rigid; continuous flesh blends at joints.
        p=v.co if o.name.startswith('Sculpted') else center
        for bn,w in weights(p,o.name).items():
            if w>0:groups[bn].add([v.index],w,'REPLACE')
    o.parent=rig
    mod=o.modifiers.new('Skeleton','ARMATURE');mod.object=rig
bpy.ops.object.select_all(action='DESELECT')
for o in meshes:o.select_set(True)
bpy.context.view_layer.objects.active=meshes[0];bpy.ops.object.join()
mesh=bpy.context.object;mesh.name='ChamelenoidMesh'

# Key every channel on every frame so cancelling attack restores the jaw and limbs.
fps=30;bpy.context.scene.render.fps=fps
def arm_target(side,target):
    upper=rigdata.bones['upper_arm.'+side];fore=rigdata.bones['forearm.'+side]
    shoulder=upper.head_local;v=Vector(target)-shoulder
    length=min(v.length,(upper.length+fore.length)*.97);direction=v.normalized()
    a=(upper.length**2-fore.length**2+length**2)/(2*length)
    pole=Vector((.6 if side=='R' else -.6,.10,-1.0))
    pole=(pole-direction*pole.dot(direction)).normalized()
    elbow=shoulder+direction*a+pole*math.sqrt(max(0,upper.length**2-a*a))
    wrist=shoulder+direction*length
    du=(upper.tail_local-upper.head_local).rotation_difference(elbow-shoulder)
    df=(fore.tail_local-fore.head_local).rotation_difference(wrist-elbow)
    qu=upper.matrix_local.to_quaternion();qf=fore.matrix_local.to_quaternion()
    rig.pose.bones[upper.name].rotation_quaternion=qu.inverted() @ du @ qu
    rig.pose.bones[fore.name].rotation_quaternion=qf.inverted() @ du.inverted() @ df @ qf

def leg_target(side,target,shift):
    upper=rigdata.bones['thigh.'+side];lower=rigdata.bones['shin.'+side];foot=rigdata.bones['foot.'+side]
    hip=upper.head_local+shift;v=Vector(target)-hip
    length=min(v.length,(upper.length+lower.length)*.995);direction=v.normalized()
    a=(upper.length**2-lower.length**2+length**2)/(2*length)
    pole=Vector((0,-1,0));pole=(pole-direction*pole.dot(direction)).normalized()
    knee=hip+direction*a+pole*math.sqrt(max(0,upper.length**2-a*a))
    ankle=hip+direction*length
    du=(upper.tail_local-upper.head_local).rotation_difference(knee-hip)
    dl=(lower.tail_local-lower.head_local).rotation_difference(ankle-knee)
    qu=upper.matrix_local.to_quaternion();ql=lower.matrix_local.to_quaternion();qf=foot.matrix_local.to_quaternion()
    rig.pose.bones[upper.name].rotation_quaternion=qu.inverted() @ du @ qu
    rig.pose.bones[lower.name].rotation_quaternion=ql.inverted() @ du.inverted() @ dl @ ql
    rig.pose.bones[foot.name].rotation_quaternion=qf.inverted() @ dl.inverted() @ qf

def pose(t,mode):
    for p in rig.pose.bones:p.rotation_mode='XYZ';p.rotation_euler=(0,0,0);p.location=(0,0,0)
    attack=mode.startswith('Attack')
    if mode=='Walk':
        phase=t*math.tau
        compression=.075+.018*(.5+.5*math.cos(2*phase))
        shift=Vector((.025*math.cos(phase),0,-compression))
        rig.pose.bones['pelvis'].location=rigdata.bones['pelvis'].matrix_local.to_quaternion().inverted() @ shift
        rig.pose.bones['chest'].rotation_euler.x=.09
        rig.pose.bones['chest'].rotation_euler.y=.055*math.sin(phase)
        rig.pose.bones['chest'].rotation_euler.z=.035*math.cos(phase)
        rig.pose.bones['head'].rotation_euler.x=-.07
        for side,offset in [('L',0),('R',math.pi)]:
            a=math.sin(phase+offset-.25)
            rig.pose.bones['upper_arm.'+side].rotation_euler.x=-.12*a
            rig.pose.bones['forearm.'+side].rotation_euler.x=-.12
    elif mode=='Stagger':
        pulse=math.sin(math.pi*smooth(0,.70,t))
        rig.pose.bones['chest'].rotation_euler.x=-.24*pulse
        rig.pose.bones['head'].rotation_euler.x=.15*pulse
        rig.pose.bones['jaw'].rotation_euler.x=-.25*pulse
        for side in ['L','R']:
            rig.pose.bones['upper_arm.'+side].rotation_euler.x=-.30*pulse
            rig.pose.bones['forearm.'+side].rotation_euler.x=-.40*pulse
    elif mode=='Death':
        collapse=smooth(0,.55,t);fall=smooth(.45,1.55,t)
        rig.pose.bones['chest'].rotation_euler.x=.32*collapse*(1-.5*fall)
        rig.pose.bones['head'].rotation_euler.x=.22*collapse
        rig.pose.bones['jaw'].rotation_euler.x=-.32*collapse
        for side in ['L','R']:
            rig.pose.bones['thigh.'+side].rotation_euler.x=.35*collapse
            rig.pose.bones['shin.'+side].rotation_euler.x=-.70*collapse
            rig.pose.bones['upper_arm.'+side].rotation_euler.x=-.24*collapse
            rig.pose.bones['forearm.'+side].rotation_euler.x=-.40*collapse
    elif attack:
        sign=1 if mode=='AttackRight' else -1
        pull=smooth(0,.60,t);sweep=smooth(.60,.96,t);recover=smooth(.98,1.45,t)
        rig.pose.bones['chest'].rotation_euler.y=sign*(.40-.85*sweep)*pull*(1-recover)
        rig.pose.bones['chest'].rotation_euler.x=.19*smooth(.52,.78,t)*(1-recover)
        rig.pose.bones['head'].rotation_euler.x=-.09*pull*(1-recover)
        rig.pose.bones['hand.'+('R' if sign==1 else 'L')].rotation_euler.y=-sign*.85*pull*(1-recover)
        drive=math.sin(math.pi*smooth(.48,1.20,t))
        rig.pose.bones['thigh.'+('R' if sign==1 else 'L')].rotation_euler.x=.16*drive
        rig.pose.bones['shin.'+('R' if sign==1 else 'L')].rotation_euler.x=-.20*drive
        rig.pose.bones['jaw'].rotation_euler.x=-.62*smooth(.25,.65,t)*(1-recover)
        other='L' if sign==1 else 'R'
        rig.pose.bones['upper_arm.'+other].rotation_euler.z=-sign*.30*pull*(1-recover)
        rig.pose.bones['upper_arm.'+other].rotation_euler.x=-.20*pull*(1-recover)
    else:rig.pose.bones['chest'].rotation_euler.x=.008*math.sin(t*math.tau/2)
    for p in rig.pose.bones:
        q=p.rotation_euler.to_quaternion();p.rotation_mode='QUATERNION';p.rotation_quaternion=q
    if mode=='Walk':
        for side,offset in [('L',0),('R',.5)]:
            step=(t+offset)%1
            # Long planted support; short low-clearance swing.
            if step<.65: y=-.39+.78*step/.65;lift=0
            else:
                u=(step-.65)/.35;y=.39-.78*smooth(0,1,u);lift=.075*math.sin(math.pi*u)
            leg_target(side,Vector((-.30 if side=='L' else .30,.015+y,.17+lift)),shift)
    elif mode=='Death':
        q=rigdata.bones['pelvis'].matrix_local.to_quaternion()
        rig.pose.bones['pelvis'].rotation_quaternion=q.inverted() @ Quaternion((0,1,0),1.52*fall) @ q
        rig.pose.bones['pelvis'].location=q.inverted() @ Vector((.22*fall,0,-.20*collapse-.72*fall))
        bpy.context.view_layer.update()
        obj=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get());evaluated=obj.to_mesh()
        floor=min(v.co.z for v in evaluated.vertices);obj.to_mesh_clear()
        if floor<.004:rig.pose.bones['pelvis'].location+=q.inverted() @ Vector((0,0,.004-floor))
    if attack:
        side='R' if sign==1 else 'L'
        rest=rigdata.bones['forearm.'+side].tail_local.copy()
        wide=Vector((sign*1.04,-.08,1.96))
        front=Vector((sign*.22,-.72,1.64))
        across=Vector((-sign*.34,-.40,1.32))
        target=rest.lerp(wide,pull)
        if t>=.60:target=wide.lerp(front,smooth(.60,.78,t))
        if t>=.78:target=front.lerp(across,smooth(.78,.98,t))
        target=target.lerp(rest,recover)
        if pull*(1-recover)>.00001:arm_target(side,target)

rig.animation_data_create()
for mode,duration in [('Idle',2),('Walk',1),('AttackRight',1.5),('AttackLeft',1.5),('Stagger',.7),('Death',1.8)]:
    action=bpy.data.actions.new(mode);rig.animation_data.action=action
    for f in range(round(duration*fps)+1):
        pose(f/fps,mode)
        for p in rig.pose.bones:
            p.keyframe_insert(data_path='rotation_quaternion',frame=f)
            p.keyframe_insert(data_path='location',frame=f)
    for fc in action.fcurves:
        for k in fc.keyframe_points:k.interpolation='LINEAR'
    track=rig.animation_data.nla_tracks.new();track.name=mode
    strip=track.strips.new(mode,0,action);track.mute=True
rig.animation_data.action=None;pose(0,'Idle')
bpy.context.scene.frame_set(0)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE,'Chamelenoid_reconstruido.blend'))
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,'chamelenoid.glb'),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_frame_range=False,export_force_sampling=True,export_materials='EXPORT',export_yup=True)
mesh.data.calc_loop_triangles()
report={'triangles':len(mesh.data.loop_triangles),'vertices':len(mesh.data.vertices),'bones':len(rigdata.bones),'animations':['Idle','Walk','AttackRight','AttackLeft','Stagger','Death'],'materials':'Vertex colors; procedural microdetail approximated, not texture-baked'}
with open(os.path.join(OUT,'build_report.json'),'w') as f:json.dump(report,f,indent=2)
print('REBUILD_COMPLETE',report,flush=True)










