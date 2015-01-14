class NewTrilinos < Formula
  homepage "http://trilinos.sandia.gov"
  url "http://trilinos.org/oldsite/download/files/trilinos-11.12.1-Source.tar.bz2"
  sha1 "f24f401e2182003eb648d47a8e50a6322fdb79ec"
  head "https://software.sandia.gov/trilinos/repositories/publicTrilinos", :using => :git

  option "with-teko",  "Enable the Teko secondary-stable package"
  option "with-shylu", "Enable the ShyLU experimental package"
  option "with-check", "Perform build time checks (time consuming and contains failures)"
  option :cxx11

  option "with-cholmod", "Build with Cholmod (Experimental TPL) from suite-sparse"
  option "with-csparse", "Build with CSparse (Experimental TPL) from suite-sparse"

  depends_on :mpi           => [:cc, :cxx, :recommended]
  depends_on :fortran       => :recommended
  depends_on :x11           => :recommended

  depends_on :python        => ["numpy", :recommended]
  depends_on "swig"         => :build if build.with? :python

  depends_on "cmake"        => :build
  depends_on "boost"        => :recommended
  depends_on "scotch"       => :recommended
  depends_on "netcdf"       => :optional
  depends_on "adol-c"       => :optional # TODO: move ADOL-C's config.h to prefix/include/adolc/config.h
  depends_on "suite-sparse" => :recommended
  depends_on "cppunit"      => :optional
  depends_on "eigen"        => :optional #Experimental TPL, Intrepid_test_Discretization_Basis_HGRAD_TET_Cn_FEM_ORTH_Test_02 fails to build
  depends_on "glpk"         => :optional #Experimental TPL
  depends_on "homebrew/versions/hdf5-1.8.12" => [:optional] + ((build.with? :mpi) ? ["with-mpi"] : []) #Experimental TPL
  depends_on "hwloc"        => :optional
  depends_on "hypre"        => [:optional] + ((build.with? :mpi) ? ["with-mpi"] : []) # Currently fails, experimental TPL
  depends_on "metis"        => :optional
  depends_on "mumps"        => :optional
  depends_on "petsc"        => :optional # ML packages in the current state does not compile with Petsc >= 3.3
  depends_on "parmetis"     => :optional if build.with? :mpi
  depends_on "scalapack"    => :optional
  depends_on "superlu"      => :optional
  depends_on "superlu_dist" => :optional if build.with? :mpi # Currently fails
  depends_on "tbb"          => :recommended #Experimental TPL => :optional?
  depends_on "qd"           => :optional # Currently fails due to global namespace issues
  depends_on "lemon"        => :optional #Experimental TPL, lemon is currently built as executable only, no libraries!
  depends_on "glm"          => :optional #Experimental TPL
  depends_on "cask"         => :optional #Experimental TPL, cask is currently built as executable only, no libraries!
  depends_on "binutils"     => :optional #Currently fails: Could not find a library in the set "iberty" for the TPL BinUtils!

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
               -DSacado_ENABLE_TESTS=OFF
               -DEpetraExt_ENABLE_TESTS=OFF]  # --with-hypre fails without this.

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

    # when CSparse is enabled: Undefined symbols for architecture x86_64: "Amesos_CSparse::Amesos_CSparse(Epetra_LinearProblem const&)"
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

    # TODO: apparently Trilinos needs BLACS for Scalapack
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
