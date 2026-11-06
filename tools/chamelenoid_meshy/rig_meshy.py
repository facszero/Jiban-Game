import bpy,math,os,json
from mathutils import Vector,Quaternion
import argparse,sys
parser=argparse.ArgumentParser(description='Rig the normalized Meshy working GLB in Blender 4.3.2')
parser.add_argument('--source',required=True,help='Normalized meshy_optimized_static.glb from the working archive')
parser.add_argument('--output',required=True,help='Directory for runtime GLB and build report')
parser.add_argument('--blend',required=True,help='Path for the editable Blender project')
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
OUT=os.path.abspath(args.output);os.makedirs(OUT,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
cached=os.path.abspath(args.source)
bpy.ops.import_scene.gltf(filepath=cached)
mesh=next(o for o in bpy.context.scene.objects if o.type=='MESH')
bpy.context.view_layer.objects.active=mesh
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
mesh.name='ChamelenoidMesh'

def clamp(x):return max(0,min(1,x))
def smooth(a,b,x):
 t=clamp((x-a)/(b-a));return t*t*(3-2*t)
rigdata=bpy.data.armatures.new('ChamelenoidSkeleton');rig=bpy.data.objects.new('ChamelenoidRig',rigdata);bpy.context.collection.objects.link(rig)
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig;bpy.ops.object.mode_set(mode='EDIT')
def bone(name,a,b,parent=None):
 q=rigdata.edit_bones.new(name);q.head=a;q.tail=b
 if parent:q.parent=rigdata.edit_bones[parent]
 return q
bone('pelvis',(0,0,1.28),(0,0,1.53))
bone('chest',(0,0,1.53),(0,.01,2.16),'pelvis')
bone('head',(0,.01,2.16),(0,-.01,2.60),'chest')
bone('jaw',(0,-.08,2.30),(0,-.17,2.20),'head')
for sign,side in [(-1,'L'),(1,'R')]:
 bone('upper_arm.'+side,(sign*.49,0,2.11),(sign*.57,-.005,1.67),'chest')
 bone('forearm.'+side,(sign*.57,-.005,1.67),(sign*.64,-.045,1.23),'upper_arm.'+side)
 bone('hand.'+side,(sign*.64,-.045,1.23),(sign*.65,-.06,1.04),'forearm.'+side)
 bone('thigh.'+side,(sign*.22,0,1.28),(sign*.29,-.035,.73),'pelvis')
 bone('shin.'+side,(sign*.29,-.035,.73),(sign*.31,.015,.18),'thigh.'+side)
 bone('foot.'+side,(sign*.31,.015,.18),(sign*.31,-.24,.08),'shin.'+side)
bpy.ops.object.mode_set(mode='OBJECT')
# Anatomical regions avoid the failed heat solver on the generated surface.
# Blend only across each joint; the gap beside the hip separates hands from legs.
from mathutils.kdtree import KDTree
vs=mesh.data.vertices
parent=list(range(len(vs)))
def find(i):
 while parent[i]!=i:parent[i]=parent[parent[i]];i=parent[i]
 return i
def union(a,b):
 a=find(a);b=find(b)
 if a!=b:parent[a]=b
kd=KDTree(len(vs))
for v in vs:kd.insert(v.co,v.index)
kd.balance()
for e in mesh.data.edges:
 a,b=e.vertices
 if max(vs[a].co.z,vs[b].co.z)<1.82:union(a,b)
for v in vs:
 if v.co.z<1.82:
  for co,j,d in kd.find_range(v.co,.008):
   if co.z<1.82:union(v.index,j)
parts={}
for v in vs:
 if v.co.z<1.82:parts.setdefault(find(v.index),[]).append(v.index)
mainparts=sorted(parts.values(),key=len,reverse=True)[:3]
region_tree=KDTree(sum(len(p) for p in mainparts))
for region,part in enumerate(mainparts):
 for i in part:region_tree.insert(vs[i].co,region)
region_tree.balance()
region_trees=[]
for part in mainparts:
 tree=KDTree(len(part))
 for i in part:tree.insert(vs[i].co,i)
 tree.balance();region_trees.append(tree)

def blend(a,b,w):return {a:1-w,b:w}
def anatomical_weights(p):
 x,y,z=p;ax=abs(x);side='L' if x<0 else 'R'
 region=region_tree.find(Vector((x,y,min(z,1.81))))[1]
 arm_low=0.0 if region==0 else 1.0
 query=Vector((x,y,min(z,1.81)))
 db=region_trees[0].find(query)[2]
 da=min(tree.find(query)[2] for tree in region_trees[1:])
 arm_soft=smooth(-.10,.10,db-da)
 transition=smooth(1.65,1.82,z)
 arm=arm_low*(1-transition)+arm_soft*transition
 if z>2.27:arm=0
 if z<.29:body=blend('foot.'+side,'shin.'+side,smooth(.13,.29,z))
 elif z<.95:body=blend('shin.'+side,'thigh.'+side,smooth(.62,.87,z))
 elif z<1.40:
  pelvis=smooth(1.12,1.40,z)
  right=smooth(-.10,.10,x)
  body={'pelvis':pelvis,'thigh.L':(1-pelvis)*(1-right),'thigh.R':(1-pelvis)*right}
 elif z<1.75:body=blend('pelvis','chest',smooth(1.40,1.65,z))
 else:body=blend('chest','head',smooth(2.13,2.31,z))
 if z<1.44:limb=blend('hand.'+side,'forearm.'+side,smooth(1.15,1.32,z))
 else:limb=blend('forearm.'+side,'upper_arm.'+side,smooth(1.54,1.78,z))
 if z>2.10:arm*=1-smooth(2.10,2.27,z)
 w={k:v*(1-arm) for k,v in body.items()}
 for k,v in limb.items():w[k]=w.get(k,0)+v*arm
 return w
mesh.vertex_groups.clear()
groups={b.name:mesh.vertex_groups.new(name=b.name) for b in rigdata.bones}
for v in mesh.data.vertices:
 weights=anatomical_weights(v.co)
 weights=dict(sorted(weights.items(),key=lambda item:item[1],reverse=True)[:4]);total=sum(weights.values())
 for group,w in weights.items():
  if w>0:groups[group].add([v.index],w/total,'REPLACE')
mesh.parent=rig
if not any(m.type=='ARMATURE' for m in mesh.modifiers):
 mod=mesh.modifiers.new('Skeleton','ARMATURE');mod.object=rig
# Inspect weights before generating the runtime asset.
unweighted=sum(not any(g.weight>.0001 for g in v.groups) for v in mesh.data.vertices)
print('UNWEIGHTED',unweighted,flush=True)
if unweighted:raise RuntimeError('Automatic weighting incomplete; inspect source before export')

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
        compression=.065+.012*(.5+.5*math.cos(2*phase))
        shift=Vector((.012*math.cos(phase),0,-compression))
        rig.pose.bones['pelvis'].location=rigdata.bones['pelvis'].matrix_local.to_quaternion().inverted() @ shift
        rig.pose.bones['chest'].rotation_euler.x=.09
        rig.pose.bones['chest'].rotation_euler.y=.055*math.sin(phase)
        rig.pose.bones['chest'].rotation_euler.z=.035*math.cos(phase)
        rig.pose.bones['head'].rotation_euler.x=-.07
        for side,offset in [('L',0),('R',math.pi)]:
            a=math.sin(phase+offset-.25)
            rig.pose.bones['upper_arm.'+side].rotation_euler.x=-.22*a
            rig.pose.bones['forearm.'+side].rotation_euler.x=-.22
    elif mode=='Stagger':
        pulse=math.sin(math.pi*smooth(0,.70,t))
        rig.pose.bones['chest'].rotation_euler.x=-.24*pulse
        rig.pose.bones['head'].rotation_euler.x=.15*pulse
        rig.pose.bones['jaw'].rotation_euler.x=-.25*pulse
        for side in ['L','R']:
            rig.pose.bones['upper_arm.'+side].rotation_euler.x=-.30*pulse
            rig.pose.bones['forearm.'+side].rotation_euler.x=-.40*pulse
    elif mode=='Death':
        collapse=smooth(0,.60,t);fall=smooth(.40,1.45,t)
        rig.pose.bones['chest'].rotation_euler.x=.45*collapse*(1-.85*fall)
        rig.pose.bones['head'].rotation_euler.x=.12*collapse
        rig.pose.bones['jaw'].rotation_euler.x=-.32*collapse
        for side in ['L','R']:
            rig.pose.bones['thigh.'+side].rotation_euler.x=.55*collapse*(1-.85*fall)
            rig.pose.bones['shin.'+side].rotation_euler.x=-1.05*collapse*(1-.85*fall)
            rig.pose.bones['upper_arm.'+side].rotation_euler.x=-.35*collapse*(1-fall)+.08*fall
            rig.pose.bones['forearm.'+side].rotation_euler.x=-.65*collapse*(1-fall)-.12*fall
            rig.pose.bones['foot.'+side].rotation_euler.x=-.70*fall
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
            # Stance travel matches GAIT_PER_METER; swing clears the floor.
            if step<.56: y=-.36+.72*step/.56;lift=0
            else:
                u=(step-.56)/.44;y=.36-.72*smooth(0,1,u);lift=.16*math.sin(math.pi*u)
            leg_target(side,Vector((-.31 if side=='L' else .31,.015+y,.18+lift)),shift)
    elif mode=='Death':
        q=rigdata.bones['pelvis'].matrix_local.to_quaternion()
        rig.pose.bones['pelvis'].rotation_quaternion=q.inverted() @ Quaternion((0,0,1),.12*fall) @ Quaternion((1,0,0),1.53*fall) @ q
        rig.pose.bones['pelvis'].location=q.inverted() @ Vector((.04*fall,-.35*fall,-.35*collapse-.75*fall))
        bpy.context.view_layer.update()
        obj=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get());evaluated=obj.to_mesh()
        floor=min(v.co.z for v in evaluated.vertices);obj.to_mesh_clear()
        rig.pose.bones['pelvis'].location+=q.inverted() @ Vector((0,0,.004-floor))
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
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(args.blend))
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,'chamelenoid.glb'),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_frame_range=False,export_force_sampling=True,export_materials='EXPORT',export_yup=True)
mesh.data.calc_loop_triangles()
report={'source':'Meshy user-provided GLB','triangles':len(mesh.data.loop_triangles),'vertices':len(mesh.data.vertices),'bones':len(rigdata.bones),'animations':['Idle','Walk','AttackRight','AttackLeft','Stagger','Death'],'materials':'Original Meshy PBR textures preserved'}
with open(os.path.join(OUT,'build_report.json'),'w') as f:json.dump(report,f,indent=2)
print('REBUILD_COMPLETE',report,flush=True)










