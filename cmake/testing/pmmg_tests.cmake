IF( BUILD_TESTING )
  include( CTest )

  set( CI_DIR  ${CMAKE_BINARY_DIR}/Tests )
  file( MAKE_DIRECTORY ${CI_DIR} )
  set( CI_DIR_RESULTS  ${CI_DIR}/output )
  file( MAKE_DIRECTORY ${CI_DIR_RESULTS} )
  set( CI_DIR_INPUTS  "../../testparmmg" CACHE PATH "path to test meshes repository" )

  # remesh 2 sets of matching mesh/sol files (which are the output of mmg3d)
  # on 1,2,4,6,8 processors
  foreach( MESH cube-unit-dual_density cube-unit-int_sphere )
    foreach( NP 1 2 4 6 8 )
      add_test( NAME ${MESH}-${NP}
        COMMAND ${MPIEXEC} -np ${NP} $<TARGET_FILE:${PROJECT_NAME}>
        ${CI_DIR_INPUTS}/Cube/${MESH}.mesh
        -out ${CI_DIR_RESULTS}/${MESH}-${NP}-out.mesh
        -m 11000 )
    endforeach()
  endforeach()

  # remesh a unit cube with two different solution files on 1,2,4,6,8 processors
  foreach( MESH dual_density int_sphere )
    foreach( NP 1 2 4 6 8 )
      add_test( NAME cube-unit-coarse-${MESH}-${NP}
        COMMAND ${MPIEXEC} -np ${NP} $<TARGET_FILE:${PROJECT_NAME}>
        ${CI_DIR_INPUTS}/Cube/cube-unit-coarse.mesh
        -sol ${CI_DIR_INPUTS}/Cube/cube-unit-coarse-${MESH}.sol
        -out ${CI_DIR_RESULTS}/${MESH}-${NP}-out.mesh )
    endforeach()
  endforeach()

  # remesh a non constant anisotropic test case: a torus with a planar shock
  # on 1,2,4,6,8 processors
  foreach( TYPE anisotropic-test )
    foreach( NP 1 2 4 6 8 )
      add_test( NAME ${TYPE}-torus-with-planar-shock-${NP}
        COMMAND ${MPIEXEC} -np ${NP} $<TARGET_FILE:${PROJECT_NAME}>
        ${CI_DIR_INPUTS}/Torus/torusholes.mesh
        -sol ${CI_DIR_INPUTS}/Torus/torusholes.sol
        -out ${CI_DIR_RESULTS}/${TYPE}-torus-with-planar-shock-${NP}-out.mesh )
    endforeach()
  endforeach()

  ###############################################################################
  #####
  #####        Tests that needs the PARMMG LIBRARY
  #####
  ###############################################################################

  SET ( PMMG_LIB_TESTS
    LnkdList_unitTest
    libparmmg_centralized_auto_example0
    )

  SET ( PMMG_LIB_TESTS_MAIN_PATH
    ${CI_DIR_INPUTS}/LnkdList_unitTest/main.c
    ${PROJECT_SOURCE_DIR}/libexamples/adaptation_example0/sequential_IO/automatic_IO/main.c
    )

  SET ( PMMG_LIB_TESTS_INPUTMESH
    ""
    ${PROJECT_SOURCE_DIR}/libexamples/adaptation_example0/torus.mesh
    )

  SET ( PMMG_LIB_TESTS_INPUTMET
    ""
    ${PROJECT_SOURCE_DIR}/libexamples/adaptation_example0/torus_met.sol
    )

  SET ( PMMG_LIB_TESTS_INPUTSOL
    ""
    ""
    )

  SET ( PMMG_LIB_TESTS_OUTPUTMESH
    ""
    ${CI_DIR_RESULTS}/io-seq-auto-torus.o.mesh
    )

  IF ( LIBPARMMG_STATIC )
    SET ( lib_name lib${PROJECT_NAME}_a )
  ELSEIF ( LIBPARMMG_SHARED )
    SET ( lib_name lib${PROJECT_NAME}_so )
  ELSE ()
    MESSAGE(WARNING "You must activate the compilation of the static or"
      " shared ${PROJECT_NAME} library to compile this tests." )
  ENDIF ( )

  #####         Fortran Tests
  IF ( CMAKE_Fortran_COMPILER )
    ENABLE_LANGUAGE ( Fortran )

    SET ( PMMG_LIB_TESTS ${PMMG_LIB_TESTS}
      )

    SET ( PMMG_LIB_TESTS_MAIN_PATH ${PMMG_LIB_TESTS_MAIN_PATH}
      )
  ENDIF ( CMAKE_Fortran_COMPILER )


  LIST(LENGTH PMMG_LIB_TESTS nbTests_tmp)
  MATH(EXPR nbTests "${nbTests_tmp} - 1")

  FOREACH ( test_idx RANGE ${nbTests} )
    LIST ( GET PMMG_LIB_TESTS            ${test_idx} test_name )
    LIST ( GET PMMG_LIB_TESTS_MAIN_PATH  ${test_idx} main_path )
    LIST ( GET PMMG_LIB_TESTS_INPUTMESH  ${test_idx} input_mesh )
    LIST ( GET PMMG_LIB_TESTS_INPUTMET   ${test_idx} input_met )
    LIST ( GET PMMG_LIB_TESTS_INPUTSOL   ${test_idx} input_sol )
    LIST ( GET PMMG_LIB_TESTS_OUTPUTMESH ${test_idx} output_mesh )

    ADD_LIBRARY_TEST ( ${test_name} ${main_path} copy_pmmg_headers ${lib_name} )

    FOREACH( NP 1 2 8 )
      ADD_TEST ( NAME ${test_name}-${NP} COMMAND  ${MPIEXEC} -np ${NP}
        $<TARGET_FILE:${test_name}>
        ${input_mesh} ${output_mesh} -met ${input_met} )
    ENDFOREACH()

  ENDFOREACH ( )

ENDIF()
