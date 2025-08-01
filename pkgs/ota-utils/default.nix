{ lib, stdenvNoCC, bash, util-linux, e2fsprogs, tegra-eeprom-tool, efiSysMountPoint ? "/boot", expectedBiosVersion ? "Unknown" }:

stdenvNoCC.mkDerivation {
  name = "ota-utils";

  depsBuildHost = [ bash ];

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  env = { inherit efiSysMountPoint; };

  buildInputs = [ bash ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share
    cp ${./ota-setup-efivars.sh} $out/bin/ota-setup-efivars
    cp ${./ota-apply-capsule-update.sh} $out/bin/ota-apply-capsule-update
    cp ${./ota-check-firmware.sh} $out/bin/ota-check-firmware
    cp ${./ota_helpers.func} $out/share/ota_helpers.func
    chmod +x $out/bin/ota-setup-efivars $out/bin/ota-apply-capsule-update $out/bin/ota-check-firmware

    for path in $out/bin/ota-apply-capsule-update $out/share/ota_helpers.func; do
      substituteInPlace "$path" --subst-var efiSysMountPoint
    done

    for fname in ota-setup-efivars ota-apply-capsule-update; do
      substituteInPlace $out/bin/$fname \
        --replace "@ota_helpers@" "$out/share/ota_helpers.func"
      sed -i '2a export PATH=${lib.makeBinPath [ util-linux e2fsprogs tegra-eeprom-tool ]}:$PATH' $out/bin/$fname
    done

    substituteInPlace $out/bin/ota-check-firmware \
      --replace "@expectedBiosVersion@" "${expectedBiosVersion}"

    patchShebangs --host $out/bin

    runHook postInstall
  '';
}
