#!/usr/bin/env python3
import argparse, os, re, sqlite3, time
import osmium

def clean(v): return re.sub(r'\s+', ' ', (v or '').strip())
def norm(v): return re.sub(r'\s+', ' ', re.sub(r'[^a-z0-9]+', ' ', clean(v).lower())).strip()

def label(t):
    house, street = clean(t.get('addr:housenumber')), clean(t.get('addr:street'))
    suburb = clean(t.get('addr:suburb') or t.get('addr:neighbourhood') or t.get('addr:place'))
    city = clean(t.get('addr:city') or t.get('addr:town') or t.get('addr:village'))
    postcode, name, ref = clean(t.get('addr:postcode')), clean(t.get('name')), clean(t.get('ref'))
    p = [f'{house} {street}'] if house and street else [street or name or ref or house]
    p = [x for x in p if x]
    for x in (suburb, city, postcode):
        if x and x not in p: p.append(x)
    return ', '.join(p)

def importance(t):
    place, road = t.get('place',''), t.get('highway','')
    if place == 'city': return 100
    if place == 'town': return 95
    if place in ('suburb','village'): return 90
    if t.get('addr:housenumber'): return 88
    if place in ('neighbourhood','hamlet'): return 84
    if road in ('motorway','trunk','primary'): return 82
    if road: return 76
    return 70

class H(osmium.SimpleHandler):
    def __init__(self, db):
        super().__init__(); self.db=db; self.batch=[]; self.seen=set(); self.total=0
    def wanted(self,t):
        return bool(t.get('addr:housenumber') or t.get('addr:street') or t.get('place') or
                    (t.get('highway') and (t.get('name') or t.get('ref'))) or
                    t.get('amenity') or t.get('shop') or t.get('tourism') or t.get('leisure'))
    def add(self, oid, typ, t, lat, lon):
        if not self.wanted(t) or not (-35.5 <= lat <= -22 and 16 <= lon <= 33.5): return
        name=label(t)
        if not name: return
        text=norm(' '.join(str(x) for x in [name,t.get('name'),t.get('ref'),t.get('addr:housenumber'),t.get('addr:street'),t.get('addr:suburb'),t.get('addr:neighbourhood'),t.get('addr:city'),t.get('addr:town'),t.get('addr:village'),t.get('addr:postcode'),t.get('amenity'),t.get('shop'),t.get('tourism')] if x))
        key=(norm(name),round(lat,5),round(lon,5))
        if not text or key in self.seen: return
        self.seen.add(key)
        self.batch.append((f'{typ}{oid}',name,text,float(lat),float(lon),importance(t)))
        if len(self.batch)>=10000: self.flush()
    def node(self,n):
        if n.location.valid(): self.add(n.id,'n',{x.k:x.v for x in n.tags},n.location.lat,n.location.lon)
    def way(self,w):
        t={x.k:x.v for x in w.tags}
        if not self.wanted(t): return
        c=[]
        for n in w.nodes:
            try:
                if n.location.valid(): c.append((n.location.lat,n.location.lon))
            except Exception: pass
        if c: self.add(w.id,'w',t,sum(x[0] for x in c)/len(c),sum(x[1] for x in c)/len(c))
    def flush(self):
        if not self.batch: return
        self.db.executemany('INSERT OR REPLACE INTO places VALUES (?,?,?,?,?,?)',self.batch); self.db.commit()
        self.total += len(self.batch); print(f'\rIndexed {self.total:,} entries...',end='',flush=True); self.batch=[]

def main(pbf,out):
    if not os.path.exists(pbf): raise SystemExit(f'PBF not found: {pbf}')
    os.makedirs(os.path.dirname(os.path.abspath(out)),exist_ok=True)
    if os.path.exists(out): os.remove(out)
    db=sqlite3.connect(out); db.execute('PRAGMA synchronous=NORMAL')
    db.executescript('CREATE TABLE places(id TEXT PRIMARY KEY,display_name TEXT NOT NULL,search_text TEXT NOT NULL,latitude REAL NOT NULL,longitude REAL NOT NULL,importance REAL NOT NULL); CREATE INDEX ix_search ON places(search_text); CREATE INDEX ix_name ON places(display_name COLLATE NOCASE);')
    h=H(db); started=time.time(); print(f'Reading {pbf}')
    h.apply_file(pbf,locations=True,idx='flex_mem'); h.flush(); db.execute('ANALYZE'); db.execute('VACUUM')
    total=db.execute('SELECT COUNT(*) FROM places').fetchone()[0]; db.close()
    print(f'\nDone: {out}\nRows: {total:,}\nSize: {os.path.getsize(out)/(1024*1024):.1f} MB\nTime: {(time.time()-started)/60:.1f} min')

if __name__=='__main__':
    p=argparse.ArgumentParser(); p.add_argument('pbf'); p.add_argument('--output',default='map_output/south_africa_search.sqlite'); a=p.parse_args(); main(a.pbf,a.output)
