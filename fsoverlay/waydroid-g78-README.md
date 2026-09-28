# Waydroid på GPU (Mali-G78 / panfrost) — recept

Datum: 2026-09-24

## Problemet (bevisat)
SurfaceFlinger i Waydroid-containern kraschar vid start:

    F RenderEngine: output buffer not gpu writeable
    renderer  : llvmpipe (LLVM ...)

Rotorsak: containern kör sin **egen Android/bionic-Mesa (26.0.1)** under
`/vendor/lib64/`. Dess `libgallium_dri.so` har panfrost men **saknar Mali-G78**
i modell-listan (verifierat: `strings libgallium_dri.so | grep G78` = tomt;
listan har G31/G51/G52/G57/G71/G72/G76/G610/G710/G720/G725 men inte G77/G78/G68).
Panfrost känner därför inte igen vår GPU (PAN_PROD_ID 9,2,2) -> faller till
**llvmpipe** -> mjukvarubuffert är inte "gpu writeable" -> abort i
`primeShaderCache`.

Allt annat är bevisat friskt:
- render-noden `/dev/dri/renderD128` når in i containern (0777)
- allocator `android.hardware.graphics.allocator@4.0-service.minigbm_gbm_mesa` KÖR (pid)
- kärnan: renderD128 -> panfrost, `arm,mali-valhall-jm`, `google,gs101-mali`
- host-desktopen kör panfrost på G78 (host-Mesan mesa-gs101/26.1.6 har vår patch)

Host-Mesan (musl) kan INTE återanvändas i containern: containern är bionic.
Två skilda userland, bara kärnan + render-noden delas.

## Fixen
Byt ENDAST containerns `/vendor/lib64/libgallium_dri.so` mot en **Android/bionic**-byggd
med G78 i modell-listan. Behåll Waydroids egen gbm/gralloc.

Mekanism: `/vendor` är read-only ext4 men monteras som overlay med
`lowerdir=/var/lib/waydroid/overlay/vendor`. Filer i
`/var/lib/waydroid/overlay/vendor/lib64/` dyker upp i containerns `/vendor/lib64/`.
Reversibelt: radera overlay-filen -> original tillbaka.

## G78-raden (samma som patchen mesa-gs101, branch gs101)
Patch: `cache_git/pmaports/temp/mesa/0001-panfrost-add-Mali-G78.patch`
(Author: Simon, 2026-08-24). Kärnan är en rad i pan_model_list:

    VALHALL_MODEL(PAN_PROD_ID(9, 2, 2), 0, "G78", "G78", MODEL_ANISO(ALL),
                  MODEL_TB_SIZES(16384, 8192), MODEL_RATES_X(2,4,8,32,32,8),
                  MODEL_QUIRKS( .no_crc = true )),

+ `bool no_crc;` i quirks-strukten (pan_model.h) och i pan_resource.c:
`if (dev->model->quirks.no_crc) return false;` i `panfrost_should_checksum`.

VIKTIGT: bygg VERSIONSMATCHAT mot containern (26.0.1), annars kan Mesa-interna
gränssnittet mot libEGL_mesa 26.0.1 spricka. I 26.0.1 kan modell-listan ligga i
`src/panfrost/model/pan_model.c` ELLER äldre `src/panfrost/lib/pan_props.c` —
kontrollera vilken filen som finns. Saknas `no_crc`-quirken i 26.0.1 kan den raden
skippas; modell-tillägget är det som krävs för att panfrost slutar falla till llvmpipe.

## Bygg (Android/bionic aarch64, på byggmaskinen)
Cross-fil `android-aarch64.ini` (NDK i PATH, API 30+):

    [binaries]
    c = 'aarch64-linux-android30-clang'
    cpp = 'aarch64-linux-android30-clang++'
    ar = 'llvm-ar'
    strip = 'llvm-strip'
    pkg-config = 'pkg-config'
    [host_machine]
    system = 'android'
    cpu_family = 'aarch64'
    cpu = 'aarch64'
    endian = 'little'

    meson setup build-android --cross-file android-aarch64.ini \
      -Dplatforms=android -Dandroid-stub=true \
      -Dgallium-drivers=panfrost,llvmpipe,zink \
      -Dvulkan-drivers=panfrost \
      -Dgbm=enabled -Degl=enabled -Dgles2=enabled \
      -Dllvm=disabled -Dbuildtype=release
    ninja -C build-android

Mål: `build-android/.../libgallium_dri.so` (64-bit).

## Lägg in + starta om (på enheten)
    sudo mkdir -p /var/lib/waydroid/overlay/vendor/lib64
    sudo cp libgallium_dri.so /var/lib/waydroid/overlay/vendor/lib64/libgallium_dri.so
    sudo chmod 644 /var/lib/waydroid/overlay/vendor/lib64/libgallium_dri.so
    waydroid session stop
    sudo waydroid container restart      # eller: sudo rc-service waydroid-container restart
    waydroid show-full-ui

## Verifiera
    sudo waydroid logcat | grep -iE "renderer|panfrost|llvmpipe|gpu writeable"

Lyckat = `renderer : Mali-G78 (Panfrost)` istället för llvmpipe, och INGEN
`output buffer not gpu writeable`. SurfaceFlinger överlever -> UI renderar på GPU.

## Fallback om ABI strular
Bygg hela Mesa-setet (libEGL_mesa/libglapi/libgallium_dri) från samma 26.0.1 och
lägg alla i overlayn tillsammans (internt konsekvent). 32-bit appar behöver samma
i `/var/lib/waydroid/overlay/vendor/lib/` senare; för att bara få upp UI räcker lib64.

## Att backa
    sudo rm /var/lib/waydroid/overlay/vendor/lib64/libgallium_dri.so
    (starta om waydroid) -> containerns original-libgallium_dri.so (26.0.1) igen.
