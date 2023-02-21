{
  description = "Shopware CLI";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let

      # Generate a user-friendly version number.
      version = "0.1.51";

      # System types to support.
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in
    {

      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        rec {
          shopware-cli = pkgs.buildGoModule {
            pname = "shopware-cli";
            inherit version;
            # In 'nix develop', we don't need a copy of the source tree
            # in the Nix store.
            src = ./.;

            nativeBuildInputs = [ pkgs.installShellFiles ];

            # This hash locks the dependencies of this package. It is
            # necessary because of how Go requires network access to resolve
            # VCS.  See https://www.tweag.io/blog/2021-03-04-gomod2nix/ for
            # details. Normally one can build with a fake sha256 and rely on native Go
            # mechanisms to tell you what the hash should be or determine what
            # it should be "out-of-band" with other tooling (eg. gomod2nix).
            # To begin with it is recommended to set this, but one must
            # remeber to bump this hash when your dependencies change.
            #vendorSha256 = pkgs.lib.fakeSha256;

            vendorSha256 = "sha256-Oz5GHafaFd5OLJTy5DD+83MYGNUWrkf4Jb0ipkIrMhg=";

            postInstall = ''
              export HOME="$(mktemp -d)"
              installShellCompletion --cmd shopware-cli \
                --bash <($out/bin/shopware-cli completion bash) \
                --zsh <($out/bin/shopware-cli completion zsh) \
                --fish <($out/bin/shopware-cli completion fish)
            '';

          };
	  default = shopware-cli;
	});

      apps = forAllSystems (system: rec {
        shopware-cli = {
	  type = "app";
	  program = "${self.packages.${system}.shopware-cli}/bin/shopware-cli";
	};
	default = shopware-cli;
      });

      defaultPackage = forAllSystems (system: self.packages.${system}.default);

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultApp = forAllSystems (system: self.apps.${system}.default);

      devShell = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in pkgs.mkShell {
          buildInputs = with pkgs; [ go golangci-lint ];
        });
    };
}
