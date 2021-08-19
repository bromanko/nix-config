self: super: rec {
  picom = super.picom.overrideAttrs (old: rec {
    version = "8.3-next";

    src = super.fetchFromGitHub {
      owner = "yshui";
      repo = "picom";
      rev = "78e8666498490ae25349a44f156d0811b30abb70";
      sha256 = "tKfMTnjmPzeGJOCRkhW5EK9bsqCvyBn60pgnLp9Awbk=";
      fetchSubmodules = true;
    };
  });
}
