"""Rebuild the game asset from the preserved sculpt; run with Blender 4.3.2."""
import bpy, math, os, json, sys, argparse
from mathutils import Vector
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
def pose(t,mode):
    for p in rig.pose.bones:p.rotation_mode='XYZ';p.rotation_euler=(0,0,0);p.location=(0,0,0)
    if mode=='Walk':
        phase=t*math.tau
        for side,offset in [('L',0),('R',math.pi)]:
            a=math.sin(phase+offset)
            rig.pose.bones['thigh.'+side].rotation_euler.x=.25*a
            rig.pose.bones['shin.'+side].rotation_euler.x=-.30*max(0,a)
            rig.pose.bones['foot.'+side].rotation_euler.x=-.25*a+.30*max(0,a)
            rig.pose.bones['upper_arm.'+side].rotation_euler.x=-.13*a
            rig.pose.bones['forearm.'+side].rotation_euler.x=.10
        rig.pose.bones['chest'].rotation_euler.y=.035*math.sin(phase)
    elif mode=='Attack':
        pull=smooth(0,.65,t);release=smooth(.65,.80,t);recover=1-smooth(.83,1.45,t)
        w=pull*recover
        rig.pose.bones['upper_arm.R'].rotation_euler.x=-(.65+.85*release)*w
        rig.pose.bones['upper_arm.R'].rotation_euler.z=(.45-.60*release)*w
        rig.pose.bones['forearm.R'].rotation_euler.x=-(.65-.45*release)*w
        rig.pose.bones['chest'].rotation_euler.y=(-.16+.32*release)*w
        rig.pose.bones['jaw'].rotation_euler.x=-.55*smooth(.35,.75,t)*recover
    else:rig.pose.bones['chest'].rotation_euler.x=.008*math.sin(t*math.tau/2)

rig.animation_data_create()
for mode,duration in [('Idle',2),('Walk',1),('Attack',1.5)]:
    action=bpy.data.actions.new(mode);rig.animation_data.action=action
    for f in range(round(duration*fps)+1):
        pose(f/fps,mode)
        for p in rig.pose.bones:
            p.keyframe_insert(data_path='rotation_euler',frame=f)
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
report={'triangles':len(mesh.data.loop_triangles),'vertices':len(mesh.data.vertices),'bones':len(rigdata.bones),'animations':['Idle','Walk','Attack'],'materials':'Vertex colors; procedural microdetail approximated, not texture-baked'}
with open(os.path.join(OUT,'build_report.json'),'w') as f:json.dump(report,f,indent=2)
print('REBUILD_COMPLETE',report,flush=True)




