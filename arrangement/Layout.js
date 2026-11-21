function overlap(a, b) {
    return Math.min(a.x+a.w,b.x+b.w) > Math.max(a.x,b.x)
        && Math.min(a.y+a.h,b.y+b.h) > Math.max(a.y,b.y);
}

function adjacent(a, b) {
    return ((a.x+a.w === b.x || b.x+b.w === a.x)
        && Math.min(a.y+a.h,b.y+b.h) > Math.max(a.y,b.y))
        || ((a.y+a.h === b.y || b.y+b.h === a.y)
        && Math.min(a.x+a.w,b.x+b.w) > Math.max(a.x,b.x));
}

function valid(rows) {
    const seen = [0];
    for (let i=0; i<rows.length; ++i)
        for (let j=0; j<i; ++j)
            if (overlap(rows[i],rows[j])) return false;
    for (let i=0; i<seen.length; ++i)
        for (let j=0; j<rows.length; ++j)
            if (seen.indexOf(j) < 0 && adjacent(rows[seen[i]],rows[j])) seen.push(j);
    return seen.length === rows.length;
}

function snap(rows, index, x, y) {
    const current = rows[index];
    let nearest = current, distance = Infinity;
    for (let i=0; i<rows.length; ++i) {
        if (i === index) continue;
        const target = rows[i];
        const cy = Math.max(target.y-current.h+32, Math.min(y,target.y+target.h-32));
        const cx = Math.max(target.x-current.w+32, Math.min(x,target.x+target.w-32));
        for (const point of [[target.x-current.w,cy],[target.x+target.w,cy],
                             [cx,target.y-current.h],[cx,target.y+target.h]]) {
            const candidate = Object.assign({},current,{x:Math.round(point[0]),y:Math.round(point[1])});
            if (rows.some((r,j) => j !== index && overlap(candidate,r))) continue;
            const cost = (candidate.x-x)**2+(candidate.y-y)**2;
            if (cost < distance) { nearest = candidate; distance = cost; }
        }
    }
    return nearest;
}

if (typeof module !== "undefined") module.exports = {snap, valid};
