"""Genera todos los efectos de sonido y la música del juego (sin assets externos).
Uso: python3 tools/generar_audio.py   (requiere numpy)"""
import numpy as np, wave, struct, os
SR = 22050
rng = np.random.default_rng(7)
BASE = os.path.join(os.path.dirname(__file__), "..", "assets")

def t(d): return np.arange(int(SR*d))/SR
def env(n, a=0.005, d=0.1, s=0.0, r=0.05, total=None):
    """ADSR simple sobre n muestras"""
    e = np.zeros(n); A=int(a*SR); D=int(d*SR); R=int(r*SR)
    A=max(A,1)
    e[:A]=np.linspace(0,1,A)[:n] if A<=n else np.linspace(0,1,n)
    if A<n:
        end=min(n,A+D); e[A:end]=np.linspace(1,s,end-A) if end>A else []
        if end<n: e[end:]=s
        if s>0 and R>0 and n>R: e[-R:]*=np.linspace(1,0,R)
    return e
def noise(n): return rng.uniform(-1,1,n)
def lp(x, a):  # filtro paso bajo de un polo (a cercano a 1 = más grave)
    y=np.zeros_like(x); acc=0.0
    for i in range(len(x)):
        acc = acc + (1-a)*(x[i]-acc); y[i]=acc
    return y
def lp_fast(x, k):  # media móvil, rápida
    k=max(1,int(k)); return np.convolve(x, np.ones(k)/k, mode="same")
def hp(x,k): return x-lp_fast(x,k)
def sweep(f0,f1,d,shape="sin"):
    tt=t(d); f=np.geomspace(f0,f1,len(tt)) if f0>0 and f1>0 else np.linspace(f0,f1,len(tt))
    ph=2*np.pi*np.cumsum(f)/SR
    if shape=="sin": return np.sin(ph)
    if shape=="sq": return np.sign(np.sin(ph))*0.6
    if shape=="saw": return 2*((ph/(2*np.pi))%1)-1
    if shape=="tri": return 2*np.abs(2*((ph/(2*np.pi))%1)-1)-1
def tone(f,d,shape="sin"): return sweep(f,f,d,shape)
def norm(x,peak=0.9):
    m=np.max(np.abs(x)) or 1; return x/m*peak
def write(name, x, loop=False, peak=0.9):
    x=norm(x,peak); data=(np.clip(x,-1,1)*32767).astype(np.int16)
    path=os.path.join(BASE,name); os.makedirs(os.path.dirname(path),exist_ok=True)
    with wave.open(path,"wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data.tobytes())
    if loop:  # chunk 'smpl' para que Godot detecte el bucle
        n=len(data)
        smpl=struct.pack("<9I",0,0,int(1e9/SR),60,0,0,0,1,0)+struct.pack("<6I",0,0,0,n-1,0,0)
        with open(path,"r+b") as f:
            f.seek(0,2); f.write(b"smpl"+struct.pack("<I",len(smpl))+smpl)
            size=f.tell()-8; f.seek(4); f.write(struct.pack("<I",size))
def cat(*xs): return np.concatenate(xs)
def mix(n,*parts):
    out=np.zeros(n)
    for start,x in parts:
        s=int(start*SR); e=min(n,s+len(x)); out[s:e]+=x[:e-s]
    return out
def sil(d): return np.zeros(int(SR*d))

# ---------------- EFECTOS ----------------
def sfx():
    # golpe de palo: click metálico + thump grave
    n=int(0.35*SR)
    click=hp(noise(n),3)*env(n,0.001,0.03)
    thump=sweep(180,60,0.35)*env(n,0.001,0.25)
    ring=tone(1650,0.35)*env(n,0.001,0.12)*0.25
    write("sfx/hit.wav", click*0.8+thump+ring)
    # rebote
    n=int(0.12*SR); write("sfx/bounce.wav", (sweep(260,140,0.12)+hp(noise(n),4)*0.3)*env(n,0.001,0.1), peak=0.6)
    # boing (bumper)
    tt=t(0.5); f=420+180*np.sin(2*np.pi*14*tt)*np.exp(-5*tt)
    b=np.sin(2*np.pi*np.cumsum(f)/SR)*env(len(tt),0.002,0.48)
    write("sfx/boing.wav", b+0.4*np.sin(2*np.pi*np.cumsum(f*2)/SR)*env(len(tt),0.002,0.3))
    # splash
    n=int(0.9*SR); s=lp(noise(n),0.6)*env(n,0.01,0.8)
    drops=mix(n,*[(rng.uniform(0.05,0.6), sweep(rng.uniform(900,1600),rng.uniform(300,600),0.06)*env(int(0.06*SR),0.001,0.05)*0.4) for _ in range(10)])
    write("sfx/splash.wav", s+drops)
    # burbujas
    n=int(1.2*SR)
    write("sfx/bubbles.wav", mix(n,*[(rng.uniform(0,1.1), sweep(rng.uniform(300,500),rng.uniform(900,1400),0.07)*env(int(0.07*SR),0.002,0.06)) for _ in range(14)]), peak=0.6)
    # chomp: dos golpes de mandíbula + crujido
    def clack(): m=int(0.09*SR); return (hp(noise(m),2)*0.6+sweep(300,80,0.09))*env(m,0.001,0.08)
    n=int(0.6*SR); crunch=hp(noise(int(0.3*SR)),3)*env(int(0.3*SR),0.005,0.28)*(rng.uniform(0,1,int(0.3*SR))>0.6)
    write("sfx/chomp.wav", mix(n,(0,clack()*1.2),(0.12,crunch*0.7),(0.32,clack()*0.6)))
    # gruñido de cocodrilo
    tt=t(0.7); f=70+15*np.sin(2*np.pi*3*tt); g=np.sign(np.sin(2*np.pi*np.cumsum(f)/SR))*lp_fast(noise(len(tt))*0.5+1,40)
    write("sfx/growl.wav", lp_fast(g,6)*env(len(tt),0.08,0.3,0.6,0.25))
    # poof de humo (eructo de humo)
    n=int(0.8*SR); p=lp(noise(n),0.85)*env(n,0.02,0.75)
    burp=sweep(110,70,0.4,"saw")*env(int(0.4*SR),0.02,0.35)*0.5
    write("sfx/poof.wav", mix(n,(0,p),(0.05,lp_fast(burp,5))))
    # chisporroteo (lava)
    n=int(1.2*SR); sz=hp(noise(n),2)*env(n,0.01,1.1)*(0.5+0.5*(rng.uniform(0,1,n)>0.7))
    write("sfx/sizzle.wav", sz*0.7+lp(noise(n),0.9)*env(n,0.01,1.0)*0.5)
    # explosión
    n=int(1.6*SR); ex=lp(noise(n),0.93)*env(n,0.002,1.5)+sweep(90,30,1.6)*env(n,0.002,1.0)*0.8
    write("sfx/explosion.wav", ex+lp(noise(n),0.6)*env(n,0.001,0.25)*0.6)
    # whoosh
    n=int(0.5*SR); w=noise(n); e=np.sin(np.linspace(0,np.pi,n))**2
    write("sfx/whoosh.wav", lp(w,0.8)*e, peak=0.6)
    # salto de hoyo / silbato que sube
    write("sfx/hop.wav", sweep(400,1400,0.25,"tri")*env(int(0.25*SR),0.005,0.24), peak=0.6)
    # chillido "¡no no no!"
    parts=[(i*0.14, sweep(900,1300,0.1,"sq")*env(int(0.1*SR),0.005,0.09)) for i in range(3)]
    write("sfx/squeak.wav", mix(int(0.45*SR),*parts), peak=0.5)
    # gravedad / warp
    tt=t(0.9); f=300+250*np.sin(2*np.pi*7*tt)+np.linspace(0,600,len(tt))
    write("sfx/warp.wav", np.sin(2*np.pi*np.cumsum(f)/SR)*env(len(tt),0.02,0.85)+0.3*np.sin(2*np.pi*np.cumsum(f*1.5)/SR)*env(len(tt),0.02,0.6), peak=0.6)
    # caída al vacío (silbato que baja)
    write("sfx/fall.wav", sweep(1500,200,1.0,"sin")*env(int(1.0*SR),0.01,0.95), peak=0.6)
    # pelota en el hoyo: traqueteo en la copa
    n=int(0.5*SR); rattle=mix(n,*[(i*0.06*(1-i*0.08), (hp(noise(int(0.03*SR)),2)*0.5+tone(2200-i*150,0.03))*env(int(0.03*SR),0.001,0.03)*(1-i*0.12)) for i in range(7)])
    write("sfx/cup.wav", rattle, peak=0.7)
    # fanfarria de victoria
    notes=[523.25,659.25,783.99,1046.5]
    fan=cat(*[ (tone(f,0.13,"saw")*0.5+tone(f*2,0.13)*0.3)*env(int(0.13*SR),0.005,0.12,0.6,0.02) for f in notes[:3]],
            (tone(1046.5,0.6,"saw")*0.5+tone(1318.5,0.6,"saw")*0.3+tone(783.99,0.6,"saw")*0.3)*env(int(0.6*SR),0.005,0.2,0.6,0.3))
    write("sfx/fanfare.wav", lp_fast(fan,3))
    # trombón triste
    segs=[]
    for i,f in enumerate([294,277,262,247]):
        d=0.35 if i<3 else 0.9; tt=t(d); ff=f*(1+0.02*np.sin(2*np.pi*6*tt)) if i==3 else np.full(len(tt),f)
        segs.append(lp_fast(np.sign(np.sin(2*np.pi*np.cumsum(ff)/SR))*0.5,8)*env(len(tt),0.03,d*0.8,0.3,0.05))
    write("sfx/sad.wav", cat(*segs))
    # click UI
    write("sfx/click.wav", tone(1200,0.05,"sq")*env(int(0.05*SR),0.001,0.045), peak=0.4)
    write("sfx/hover.wav", tone(800,0.04,"tri")*env(int(0.04*SR),0.001,0.035), peak=0.25)
    # boost
    write("sfx/boost.wav", sweep(200,1200,0.4,"saw")*env(int(0.4*SR),0.005,0.38)*0.5+lp(noise(int(0.4*SR)),0.7)*env(int(0.4*SR),0.005,0.35), peak=0.6)
    # retumbe de volcán
    n=int(2.5*SR); write("sfx/rumble.wav", lp(noise(n),0.985)*env(n,0.4,1.8,0,0.3))
    # multitud / aplausos
    n=int(2.0*SR); clap=np.zeros(n)
    for _ in range(260):
        s=int(rng.uniform(0,1.7)*SR); m=int(0.02*SR); clap[s:s+m]+=hp(noise(m),2)*env(m,0.001,0.018)*rng.uniform(0.3,1)
    write("sfx/cheer.wav", clap*env(n,0.1,1.9,0,0)+lp(noise(n),0.9)*env(n,0.2,1.7)*0.3)


def sfx_extra():
    # mecha encendida (bucle de chisporroteo)
    n=int(2.0*SR); cr=hp(noise(n),2)*(rng.uniform(0,1,n)>0.93)*rng.uniform(0.3,1,n)
    hiss=hp(noise(n),1)*0.25
    x=cr+hiss; x[:200]*=np.linspace(0,1,200); x[-200:]*=np.linspace(1,0,200)
    write("sfx/fuse.wav", x, loop=True, peak=0.5)
    # pitido de cuenta regresiva
    write("sfx/tick.wav", (tone(1760,0.07,"sq")*0.6+tone(880,0.07))*env(int(0.07*SR),0.001,0.065), peak=0.5)
    # recoger reloj: campanita ascendente
    parts=[(i*0.06, (tone(f,0.25)+0.4*tone(f*2,0.25))*env(int(0.25*SR),0.002,0.24)) for i,f in enumerate([1046.5,1318.5,1568,2093])]
    write("sfx/pickup.wav", mix(int(0.5*SR),*parts), peak=0.6)
    # resorte de trampolín
    tt=t(0.45); f=250+500*np.abs(np.sin(2*np.pi*9*tt))*np.exp(-4*tt)+np.linspace(0,500,len(tt))
    write("sfx/spring.wav", np.sin(2*np.pi*np.cumsum(f)/SR)*env(len(tt),0.002,0.43), peak=0.7)
    # zumbido de imán
    tt=t(0.8); hum=(np.sin(2*np.pi*110*tt)+0.5*np.sin(2*np.pi*220*tt)+0.3*np.sign(np.sin(2*np.pi*55*tt)))*(0.6+0.4*np.sin(2*np.pi*8*tt))
    write("sfx/magnet.wav", lp_fast(hum,4)*env(len(tt),0.05,0.7,0,0.05), peak=0.5)
    # portal
    tt=t(0.6); f=np.geomspace(1800,200,len(tt))*(1+0.1*np.sin(2*np.pi*30*tt))
    write("sfx/portal.wav", np.sin(2*np.pi*np.cumsum(f)/SR)*env(len(tt),0.005,0.58)+lp(noise(len(tt)),0.7)*env(len(tt),0.005,0.4)*0.3, peak=0.6)
    # explosión grande (bomba)
    n=int(2.4*SR); big=lp(noise(n),0.95)*env(n,0.002,2.3)+sweep(70,25,2.4)*env(n,0.002,1.6)
    crack=hp(noise(int(0.15*SR)),2)*env(int(0.15*SR),0.001,0.14)
    write("sfx/bigboom.wav", mix(n,(0,big),(0,crack*0.8)))
    # explosión ahogada dentro del cocodrilo
    n=int(0.9*SR); write("sfx/muffled.wav", lp(noise(n),0.97)*env(n,0.003,0.85)+sweep(60,35,0.9)*env(n,0.003,0.6))

# ---------------- MÚSICA ----------------
def midi(m): return 440*2**((m-69)/12)
def inst(kind, f, d, vel=1.0):
    n=int(d*SR); tt=np.arange(n)/SR
    if kind=="bass":
        x=np.sin(2*np.pi*f*tt)+0.3*np.sin(4*np.pi*f*tt); e=env(n,0.005,d*0.9,0.4,0.03)
    elif kind=="pluck":
        x=(np.sin(2*np.pi*f*tt)+0.5*np.sin(4*np.pi*f*tt)*np.exp(-8*tt)+0.25*np.sin(6*np.pi*f*tt)*np.exp(-12*tt)); e=np.exp(-5*tt)*env(n,0.003,d,1,0.02)
    elif kind=="pad":
        x=sum(np.sin(2*np.pi*f*(1+dt)*tt) for dt in (-0.004,0,0.004)); e=env(n,0.15,0.2,0.7,0.15)
    elif kind=="lead":
        vib=1+0.006*np.sin(2*np.pi*5.5*tt)*np.clip(tt*3,0,1)
        ph=2*np.pi*np.cumsum(f*vib)/SR; x=np.sign(np.sin(ph))*0.4+0.6*(2*((ph/(2*np.pi))%1)-1)
        x=lp_fast(x,4); e=env(n,0.01,0.1,0.7,0.05)
    elif kind=="organ":
        x=np.sin(2*np.pi*f*tt)+0.5*np.sin(4*np.pi*f*tt)+0.3*np.sin(8*np.pi*f*tt); e=env(n,0.01,0.05,0.8,0.05)
    elif kind=="kick":
        x=np.sin(2*np.pi*np.cumsum(np.geomspace(150,45,n))/SR); e=np.exp(-9*tt)
    elif kind=="snare":
        x=hp(noise(n),2)*0.8+np.sin(2*np.pi*190*tt)*0.4; e=np.exp(-18*tt)
    elif kind=="hat":
        x=hp(noise(n),1); e=np.exp(-60*tt)
    elif kind=="shaker":
        x=hp(noise(n),2); e=np.sin(np.linspace(0,np.pi,n))**3
    elif kind=="clave":
        x=np.sin(2*np.pi*2500*tt); e=np.exp(-40*tt)
    elif kind=="crash":
        x=hp(noise(n),1); e=np.exp(-3*tt)
    return x*e*vel

class Song:
    def __init__(s,bpm,bars,beats=4): s.bpm=bpm; s.b=60/bpm; s.n=int(bars*beats*s.b*SR); s.tracks={}
    def add(s,track,kind,beat,dur_beats,note=None,vel=1.0):
        f=midi(note) if note is not None else 0
        x=inst(kind,f,dur_beats*s.b,vel); st=int(beat*s.b*SR)
        buf=s.tracks.setdefault(track,np.zeros(s.n+SR*2)); buf[st:st+len(x)]+=x
    def render(s,gains):
        out=np.zeros(s.n+SR*2)
        for k,v in s.tracks.items(): out+=v*gains.get(k,1.0)
        # cola: sumar el exceso al inicio para un bucle limpio
        tail=out[s.n:]; out=out[:s.n].copy(); out[:len(tail)]+=tail
        return out

def chord_notes(root, q):
    iv={"maj7":[0,4,7,11],"m7":[0,3,7,10],"7":[0,4,7,10],"m":[0,3,7],"maj":[0,4,7],"dim":[0,3,6],"m7b5":[0,3,6,10]}[q]
    return [root+i for i in iv]

def menu_song():
    # bossa nova de ascensor, lo más "serio" posible antes del caos
    s=Song(118,16)
    prog=[(60,"maj7"),(57,"m7"),(62,"m7"),(55,"7")]*2+[(65,"maj7"),(64,"m7"),(62,"m7"),(55,"7")]*2
    for bar,(r,q) in enumerate(prog):
        b0=bar*4; ch=chord_notes(r,q)
        for off in (0,1.5,2.5,3.5):  # comping sincopado
            for nn in ch: s.add("keys","pluck",b0+off,0.9,nn+12,0.22)
        s.add("bass","bass",b0,1.4,r-24,0.9); s.add("bass","bass",b0+1.5,0.5,r-24+7,0.6); s.add("bass","bass",b0+2,1.4,r-24+7,0.8); s.add("bass","bass",b0+3.5,0.5,r-24,0.6)
        for i in range(8): s.add("perc","shaker",b0+i*0.5,0.5,None,0.25 if i%2 else 0.15)
        for c in (0,1.5,3,4+1,4+2.5): 
            if c<4: s.add("perc","clave",b0+c,0.2,None,0.25)
        s.add("perc","kick",b0,0.5,None,0.6); s.add("perc","kick",b0+2,0.5,None,0.5)
    mel=[(0,67,1.5),(1.5,69,0.5),(2,67,1),(3,64,1),(4,62,2),(6,64,1),(7,65,1),(8,67,1.5),(9.5,72,0.5),(10,71,1),(11,69,1),(12,67,3),
         (16,69,1.5),(17.5,71,0.5),(18,72,1),(19,74,1),(20,72,2),(22,71,1),(23,69,1),(24,71,1.5),(25.5,67,0.5),(26,65,1),(27,64,1),(28,62,3)]
    for rep in (0,32):
        for b,nn,d in mel: s.add("lead","organ",rep+b,d,nn+12,0.25)
    return s.render({"keys":1.0,"bass":1.0,"perc":0.8,"lead":0.9})

def level_song():
    # surf-ska alegre y un poco ridículo
    s=Song(150,16)
    prog=[(57,"m"),(53,"maj"),(48,"maj"),(55,"maj")]*4
    for bar,(r,q) in enumerate(prog):
        b0=bar*4; ch=chord_notes(r,q)
        for k in range(4):  # skank en contratiempo
            for nn in ch: s.add("keys","organ",b0+k+0.5,0.35,nn+12,0.18)
        for k,(o,nn) in enumerate([(0,0),(1,12),(2,7),(3,12)]): s.add("bass","bass",b0+k,0.9,r-24+nn,0.9)
        for k in range(4): s.add("dr","kick",b0+k,0.5,None,0.9 if k%2==0 else 0.5)
        s.add("dr","snare",b0+1,0.5,None,0.7); s.add("dr","snare",b0+3,0.5,None,0.7)
        for k in range(8): s.add("dr","hat",b0+k*0.5,0.25,None,0.35)
        if bar%4==3: s.add("dr","snare",b0+3.5,0.25,None,0.5); s.add("dr","snare",b0+3.75,0.25,None,0.6)
    riff=[69,72,76,74,72,69,67,69, 65,69,72,74,72,69,65,64, 64,67,72,71,72,74,76,72, 71,67,71,74,79,77,74,71]
    for rep in range(2):
        for i,nn in enumerate(riff):
            b=rep*32+i*1.0
            if (i%8) not in (3,): s.add("lead","lead",b,0.8 if i%4!=3 else 0.45,nn,0.3)
    s.add("dr","crash",0,4,None,0.4); s.add("dr","crash",32,4,None,0.4)
    return s.render({"keys":0.9,"bass":1.0,"dr":0.75,"lead":0.75})

def final_song():
    # final: polka-metal caótico en menor, rápido
    s=Song(176,16)
    prog=[(52,"m"),(52,"m"),(48,"maj"),(50,"maj"),(52,"m"),(55,"maj"),(57,"m"),(59,"maj")]*2
    for bar,(r,q) in enumerate(prog):
        b0=bar*4; ch=chord_notes(r,q)
        for k in range(4):
            s.add("bass","bass",b0+k,0.45,r-24,1.0); s.add("bass","bass",b0+k+0.5,0.45,r-12,0.7)
            for nn in ch: s.add("keys","lead",b0+k+0.5,0.3,nn,0.12)
            s.add("dr","kick",b0+k,0.4,None,1.0)
            s.add("dr","snare",b0+k+0.5,0.4,None,0.7)
            s.add("dr","hat",b0+k+0.25,0.2,None,0.3); s.add("dr","hat",b0+k+0.75,0.2,None,0.3)
        if bar%2==1:
            for k in range(4): s.add("dr","snare",b0+3+k*0.25,0.25,None,0.4+k*0.1)
    lead=[76,75,76,71,72,74,72,71, 69,71,72,74,76,79,76,74, 72,71,69,71,72,69,67,69, 71,72,74,75,76,79,83,88]
    for rep in range(2):
        for i,nn in enumerate(lead):
            s.add("lead","lead",rep*32+i,0.5,nn,0.32); s.add("lead","lead",rep*32+i+0.5,0.45,nn-12,0.2)
    for c in (0,16,32,48): s.add("dr","crash",c,4,None,0.5)
    return s.render({"keys":0.8,"bass":0.9,"dr":0.8,"lead":0.8})

def victory_song():
    s=Song(130,8)
    prog=[(60,"maj"),(65,"maj"),(67,"maj"),(60,"maj"),(65,"maj"),(67,"7"),(65,"maj"),(60,"maj")]
    for bar,(r,q) in enumerate(prog):
        b0=bar*4
        for k in range(4):
            for nn in chord_notes(r,q): s.add("keys","organ",b0+k+0.5,0.4,nn+12,0.15)
            s.add("bass","bass",b0+k,0.9,r-24+(0 if k%2==0 else 7),0.9)
            s.add("dr","kick",b0+k,0.4,None,0.8)
        s.add("dr","snare",b0+1,0.4,None,0.6); s.add("dr","snare",b0+3,0.4,None,0.6)
    mel=[72,76,79,84,83,79,76,79, 77,81,84,81,79,83,86,83, 84,79,76,72,74,77,81,79, 77,76,74,71,72,76,72,72]
    for i,nn in enumerate(mel): s.add("lead","lead",i,0.9,nn,0.3)
    return s.render({"keys":1.0,"bass":1.0,"dr":0.7,"lead":0.8})

if __name__=="__main__":
    sfx()
    sfx_extra()
    write("music/menu.wav", menu_song(), loop=True, peak=0.8)
    write("music/level.wav", level_song(), loop=True, peak=0.8)
    write("music/final.wav", final_song(), loop=True, peak=0.8)
    write("music/victory.wav", victory_song(), loop=True, peak=0.8)
    print("Audio generado en", os.path.abspath(BASE))
