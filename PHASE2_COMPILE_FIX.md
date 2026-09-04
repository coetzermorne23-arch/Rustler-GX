Ranger GX Organic Maps Phase 2 compile fix

Fixes:
- imports flutter/services.dart for StandardMessageCodec
- removes invalid const AndroidView expression
- keeps creationParams and StandardMessageCodec const where valid

Install:
  cd ~/rustler_gx
  unzip -o ~/Downloads/Rustler_GX_OrganicMaps_Phase2_compile_fix.zip -d .
  dart format lib
  flutter analyze
