{ lib
, buildPythonPackage
, fetchPypi
}:

buildPythonPackage rec {
  pname = "types-urllib3";
  version = "1.26.25.1";
  format = "setuptools";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-qUhYSUSyQSyadLnPZPbEjK+GUsuIs4NhMW9tFdihhM0=";
  };

  # Module doesn't have tests
  doCheck = false;

  pythonImportsCheck = [
    "urllib3-stubs"
  ];

  meta = with lib; {
    description = "Typing stubs for urllib3";
    homepage = "https://github.com/python/typeshed";
    license = licenses.asl20;
    maintainers = with maintainers; [ fab ];
  };
}
