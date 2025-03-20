{
  description = "ffmpeg with the DeckLink SDK";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    inherit (nixpkgs) lib;
    supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});
  in {
    formatter = forAllSystems ({pkgs, ...}: pkgs.alejandra);

    packages = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};
    in rec {
      blackmagic-decklink-sdk = let
        pname = "blackmagic-decklink-sdk";
        # curl https://www.blackmagicdesign.com/api/support/us/downloads.json | \
        #   jq '[.downloads.[]|select(any(.urls[][];.product=="desktop-video-sdk") and any(.urls[][];.major==12 and .minor==9))]'
        #version = "14.4";
        #downloadId = "fe7c7ca6891a495f831d8bdefc2d7112";
        #outputHash = "sha256-+EguuaJs6+s3M9dacRovpVGZLbrGP47h+X4pDwLHnjo=";
        # reportedly 12.9 is latest working: https://gist.github.com/afriza/879fed4ede539a5a6501e0f046f71463?permalink_comment_id=5437737#gistcomment-5437737
        version = "12.9";
        downloadId = "cfc892228821453d880022c576fae5fb";
        outputHash = "sha256-e0876VvoNqLnI8YXjaVkNldsSlkDnveHj3pijg26LCA=";

        nixKernelName = lib.lists.last (lib.strings.splitString "-" system);
        prettyPlatformName =
          {
            linux = "Linux";
            darwin = "Mac";
          }
          .${nixKernelName};
      in
        pkgs.stdenv.mkDerivation {
          inherit pname version;

          nativeBuildInputs = with pkgs; [unzip];
          src =
            pkgs.runCommandLocal "Blackmagic_DeckLink_SDK_${version}.zip" {
              nativeBuildInputs = with pkgs; [cacert curl];
              outputHashAlgo = "sha256"; # makes updating easier
              inherit outputHash;
              env = {
                URL = "https://www.blackmagicdesign.com/api/register/us/download/${downloadId}";
                USERAGENT = "Mozilla/5.0 (X11; Linux x86_64; rv:136.0) Gecko/20100101 Firefox/136.0";
                DATA = builtins.toJSON {
                  platform = prettyPlatformName;
                  policy = true;
                  hasAgreedToTerms = true;
                  firstname = "a";
                  lastname = "a";
                  street = "a";
                  city = "a";
                  state = "Ohio";
                  country = "us";
                  phone = "a";
                  email = "a@a.aa";
                  product = "Desktop Video ${version} SDK";
                };
              };
            } ''
              CDNURL=$(curl "$URL" \
                -H "User-Agent: $USERAGENT" \
                -H "Content-Type: application/json" \
                --data-raw "$DATA"
              )
              curl --retry 3 --retry-delay 3 "$CDNURL" -o "$out"
            '';

          installPhase = ''
            runHook preInstall
            mkdir "$out"
            cp -r "${prettyPlatformName}/include" "$out/"
            runHook postInstall
          '';

          meta = with lib; {
            license = licenses.unfree;
          };
        };

      ffmpeg =
        (pkgs.ffmpeg.override {withUnfree = true;})
        .overrideAttrs (prevAttrs: {
          buildInputs = prevAttrs.buildInputs ++ [blackmagic-decklink-sdk];
          configureFlags = prevAttrs.configureFlags ++ ["--enable-decklink"];
        });

      default = ffmpeg;
    });

    defaultPackage = forAllSystems (system: self.packages.${system}.default);

    #devShells = forAllSystems ({pkgs, ...}: {
    #  default = pkgs.mkShell {
    #    name = "ffmpeg-decklink";
    #    inputsFrom = [inputs.self.packages.${pkgs.system}.default];
    #  };
    #});

    overlays = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};
    in {
      blackmagic-decklink-sdk = pkgs.blackmagic-decklink-sdk;
      ffmpeg = pkgs.ffmpeg;
    });
  };
}
