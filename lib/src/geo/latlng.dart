typedef LatLng = ({double lat, double lon});


// use degrees2Radians from vector_math

// regex to migrate: LatLng\((-*[0-9]+\.*[0-9]*), *-*([0-9]+\.*[0-9]*)\)
// replace with: (lat: $1, lon: $2)