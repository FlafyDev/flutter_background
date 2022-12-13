{ lib
, buildFlutterApp
, gtk-layer-shell
}:

buildFlutterApp {
  pname = "flutter-background";
  version = "1.0.0";

  src = ../.;
  buildInputs = [
    gtk-layer-shell
  ];

  meta = with lib; {
    description = "Flutter background layershell";
    homepage = "https://github.com/FlafyDev/flutter_background";
    maintainers = [ ];
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
