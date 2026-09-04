Rustler GX Maps V2

Compile:
  cd ~/rustler_gx
  dart format lib
  flutter analyze
  flutter build apk --debug

Build SA offline address/place database:
  cd ~/rustler_gx
  chmod +x tools/build_sa_search.sh
  ./tools/build_sa_search.sh

Output:
  map_output/south_africa_search.sqlite

Copy that SQLite file to the Android radio. In MAP -> Search tap the database icon and import it once.
Your existing south_africa.mbtiles remains the vector map.
