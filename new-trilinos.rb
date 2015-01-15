class NewTrilinos < Formula
  homepage "http://trilinos.sandia.gov"
  url "http://trilinos.org/oldsite/download/files/trilinos-11.12.1-Source.tar.bz2"
  sha1 "f24f401e2182003eb648d47a8e50a6322fdb79ec"
  head "https://software.sandia.gov/trilinos/repositories/publicTrilinos", :using => :git

  option "with-teko",  "Enable the Teko secondary-stable package"                    # Problem?
  option "with-shylu", "Enable the ShyLU experimental package"                       # Problem?
  option "with-check", "Perform build time checks (time consuming and contains failures)"
  option :cxx11

  # options and dependencies which are not supported with current version
  # are commented with #-
  # A short comment at the end of those lines explain each issue.
  # They are not removed in order to avoid fruitless attempts to add them later

  option "with-cholmod", "Build with Cholmod (Experimental TPL) from suite-sparse"
  #-option "with-csparse", "Build with CSparse (Experimental TPL) from suite-sparse" # when CSparse is enabled: Undefined symbols for architecture x86_64: "Amesos_CSparse::Amesos_CSparse(Epetra_LinearProblem const&)"

  depends_on :mpi           => [:cc, :cxx, :recommended]
  depends_on :fortran       => :recommended
  depends_on :x11           => :recommended

  depends_on :python        => ["numpy", :recommended]
  depends_on "swig"         => :build if build.with? :python

  depends_on "cmake"        => :build
  depends_on "boost"        => :recommended
  depends_on "scotch"       => :recommended
  depends_on "netcdf"       => ["with-fortran",:recommended]
  depends_on "adol-c"       => :recommended
  depends_on "suite-sparse" => :recommended
  depends_on "cppunit"      => :recommended
  depends_on "hwloc"        => :recommended
  depends_on "metis"        => :recommended
  depends_on "mumps"        => :recommended
  #-depends_on "petsc"        => :optional                                          # ML packages in the current state does not compile with Petsc >= 3.3
  depends_on "parmetis"     => :recommended if build.with? :mpi
  depends_on "scalapack"    => ["with-shared-libs", :recommended]                   # TTrilinos needs BLACS for Scalapack?
  depends_on "superlu"      => :recommended
  #-depends_on "superlu_dist" => :optional if build.with? :mpi                      # packages/amesos/src/Amesos_Superludist.cpp:476:83: error: use of undeclared identifier 'DOUBLE'
  #-depends_on "qd"           => :optional                                          # Fails due to global namespace issues (std::pow vs qd::pow)
  #-depends_on "binutils"     => :optional                                          # libiberty is deliberately omitted in Homebrew (see PR #35881)

  # Experimental TPLs (all but tbb are turned off by default):
  #-depends_on "eigen"        => :optional                                          # Intrepid_test_Discretization_Basis_HGRAD_TET_Cn_FEM_ORTH_Test_02 fails to build
  depends_on "hypre"        => [:optional] + ((build.with? :mpi) ? ["with-mpi"] : []) # EpetraExt tests fail to compile
  depends_on "glpk"         => :optional
  depends_on "homebrew/versions/hdf5-1.8.12" => [:optional] + ((build.with? :mpi) ? ["with-mpi"] : [])
  depends_on "tbb"          => :recommended
  depends_on "glm"          => :optional
  #-depends_on "lemon"        => :optional                                          # lemon is currently built as executable only, no libraries
  #-depends_on "cask"         => :optional                                          # cask is currently built as executable only, no libraries

  #missing TPLS: YAML, BLACS, Y12M, XDMF, tvmet, thrust, taucs, SPARSEKIT, qpOASES, Portals, Pnetcdf, Peano, PaToH, PAPI, Pablo, Oski, OVIS, OpenNURBS, Nemesis, MF, Matio, MA28, LibTopoMap, InfiniBand, HPCToolkit, HIPS, gtest, gpcd, Gemini, ForUQTK, ExodusII, CUSPARSE, Cusp, CrayPortals, Coupler, Clp, CCOLAMD, BGQPAMI, BGPDCMF, ARPREC, ADIC

  def onoff(s, cond)
    s + ((cond) ? "ON" : "OFF")
  end

  def install
    args  = %W[-DCMAKE_INSTALL_PREFIX=#{prefix} -DCMAKE_BUILD_TYPE=Release]
    args += %w[-DBUILD_SHARED_LIBS=ON
               -DTPL_ENABLE_BLAS=ON
               -DTPL_ENABLE_LAPACK=ON
               -DTPL_ENABLE_Zlib:BOOL=ON
               -DTrilinos_ENABLE_ALL_PACKAGES=ON
               -DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES=ON
               -DTrilinos_ENABLE_TESTS:BOOL=ON
               -DTrilinos_ENABLE_EXAMPLES:BOOL=ON
               -DTrilinos_VERBOSE_CONFIGURE:BOOL=OFF
               -DTrilinos_WARNINGS_AS_ERRORS_FLAGS=""
               -DTrilinos_ENABLE_OpenMP:BOOL=OFF
               -DTPL_ENABLE_Matio=OFF
               -DSacado_ENABLE_TESTS=OFF
               -DEpetraExt_ENABLE_TESTS=OFF]  # --with-hypre fails without this.

    args << "-DTrilinos_ASSERT_MISSING_PACKAGES=OFF" if build.head?

    args << onoff("-DTPL_ENABLE_MPI:BOOL=",         (build.with? :mpi))
    args << onoff("-DTrilinos_ENABLE_OpenMP:BOOL=", (ENV.compiler != :clang))
    args << onoff("-DTrilinos_ENABLE_CXX11:BOOL=",  (build.cxx11?))

    # Extra non-default packages
    args << onoff("-DTrilinos_ENABLE_ShyLU:BOOL=",  (build.with? "shylu"))
    args << onoff("-DTrilinos_ENABLE_Teko:BOOL=",   (build.with? "teko"))

    # Third-party libraries
    args << onoff("-DTPL_ENABLE_Boost:BOOL=",       (build.with? "boost"))
    args << onoff("-DTPL_ENABLE_Scotch:BOOL=",      (build.with? "scotch"))
    args << onoff("-DTPL_ENABLE_Netcdf:BOOL=",      (build.with? "netcdf"))
    args << onoff("-DTPL_ENABLE_ADOLC:BOOL=",       (build.with? "adol-c"))

    args << onoff("-DTPL_ENABLE_AMD:BOOL=",         (build.with? "suite-sparse"))

    if (build.with? "suite-sparse") and (build.with? "csparse")
      args << "-DTPL_ENABLE_CSparse:BOOL=ON"
      args << "-DCSparse_LIBRARY_NAMES=cxsparse;amd;colamd;suitesparseconfig"
    else
      args << "-DTPL_ENABLE_CSparse:BOOL=OFF"
    end
    args << onoff("-DTPL_ENABLE_Cholmod:BOOL=",     ((build.with? "suite-sparse") and (build.with? "cholmod")) )

    #TODO?: --     Did not find UMFPACK TPL header: UFconfig.h
    args << onoff("-DTPL_ENABLE_UMFPACK:BOOL=",     (build.with? "suite-sparse"))
    args << "-DUMFPACK_LIBRARY_NAMES=umfpack;amd;colamd;cholmod;suitesparseconfig" if build.with? "suite-sparse"

    args << onoff("-DTPL_ENABLE_CppUnit:BOOL=",     (build.with? "cppunit"))
    args << "-DCppUnit_LIBRARY_DIRS=#{Formula["cppunit"].opt_lib}" if build.with? "cppunit"

    args << onoff("-DTPL_ENABLE_Eigen:BOOL=",       (build.with? "eigen"))
    args << "-DEigen_INCLUDE_DIRS=#{Formula["eigen"].opt_include}/eigen3" if build.with? "eigen"

    args << onoff("-DTPL_ENABLE_GLPK:BOOL=",        (build.with? "glpk"))
    args << onoff("-DTPL_ENABLE_HDF5:BOOL=",        (build.with? "hdf5"))
    args << onoff("-DTPL_ENABLE_HWLOC:BOOL=",       (build.with? "hwloc"))
    args << onoff("-DTPL_ENABLE_HYPRE:BOOL=",       (build.with? "hypre"))
    # METIS conflicts with ParMETIS in Trilinos config, see TPLsList.cmake in the source folder
    args << onoff("-DTPL_ENABLE_METIS:BOOL=",       ((build.with? "metis") and (build.without? "parmetis")) )
    args << onoff("-DTPL_ENABLE_MUMPS:BOOL=",       (build.with? "mumps"))
    args << onoff("-DTPL_ENABLE_PETSC:BOOL=",       (build.with? "petsc"))

    args << onoff("-DTPL_ENABLE_ParMETIS:BOOL=",    (build.with? "parmetis"))
    args << "-DParMETIS_LIBRARY_DIRS=#{Formula["parmetis"].opt_lib}" if build.with? "parmetis"
    args << "-DParMETIS_INCLUDE_DIRS=#{Formula["parmetis"].opt_include}" if build.with? "parmetis"

    args << onoff("-DTPL_ENABLE_SCALAPACK:BOOL=",   (build.with? "scalapack"))

    args << onoff("-DTPL_ENABLE_SuperLU:BOOL=",     (build.with? "superlu"))
    args << "-DSuperLU_INCLUDE_DIRS=#{Formula["superlu"].opt_include}/superlu" if build.with? "superlu"

    args << onoff("-DTPL_ENABLE_SuperLUDist:BOOL=", (build.with? "superlu_dist"))
    args << "-DSuperLUDist_INCLUDE_DIRS=#{Formula["superlu_dist"].opt_include}/superlu_dist" if build.with? "superlu_dist"

    args << onoff("-DTPL_ENABLE_QD:BOOL=",         (build.with? "qd"))
    args << onoff("-DTPL_ENABLE_Lemon:BOOL=",      (build.with? "lemon"))
    args << onoff("-DTPL_ENABLE_GLM:BOOL=",        (build.with? "glm"))
    args << onoff("-DTPL_ENABLE_CASK:BOOL=",       (build.with? "cask"))
    args << onoff("-DTPL_ENABLE_BinUtils:BOOL=",   (build.with? "binutils"))

    args << onoff("-DTPL_ENABLE_TBB:BOOL=",         (build.with? "tbb"))
    args << onoff("-DTPL_ENABLE_X11:BOOL=",         (build.with? :x11))

    args << onoff("-DTrilinos_ENABLE_Fortran=",     (build.with? :fortran))
    if build.with? :fortran
      libgfortran = `$FC --print-file-name libgfortran.a`.chomp
      ENV.append "LDFLAGS", "-L#{File.dirname libgfortran} -lgfortran"
    end

    args << onoff("-DTrilinos_ENABLE_PyTrilinos:BOOL=", (build.with? :python))
    args << "-DPyTrilinos_INSTALL_PREFIX:PATH=#{prefix}" if build.with? :python

    mkdir "build" do
      system "cmake", "..", *args, " 2>&1 | tee config.out"
      system 'grep "Final set of .*enabled SE packages" config.out > se_packages.txt'
      prefix.install "se_packages.txt"
      system "make", "VERBOSE=1"
      system ("ctest -j" + Hardware::CPU.cores) if build.with? "check"
      system "make", "install"
    end
  end

  test do
    system "#{bin}/Epetra_BasicPerfTest_test.exe", "16", "12", "1", "1", "25", "-v"
    system "mpirun", "-np", "2", "#{bin}/Epetra_BasicPerfTest_test.exe", "10", "12", "1", "2", "9", "-v" if build.with? :mpi
    system "#{bin}/Epetra_BasicPerfTest_test_LL.exe", "16", "12", "1", "1", "25", "-v"
    system "mpirun", "-np", "2", "#{bin}/Epetra_BasicPerfTest_test_LL.exe", "10", "12", "1", "2", "9", "-v" if build.with? :mpi
    # system "#{bin}/Ifpack2_BelosTpetraHybridPlatformExample.exe"  # Missing library!!
    system "#{bin}/KokkosClassic_SerialNodeTestAndTiming.exe"
    system "#{bin}/KokkosClassic_TPINodeTestAndTiming.exe"
    system "#{bin}/KokkosClassic_TBBNodeTestAndTiming.exe" if build.with? "tbb"
    system "#{bin}/Tpetra_GEMMTiming_TBB.exe" if build.with? "tbb"
    # system "#{bin}/Tpetra_GEMMTiming_TPI.exe"  # Fails!!
  end
end
