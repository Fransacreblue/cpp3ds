# DevkitPro Paths are broken on windows, so we have to fix those
macro(msys_to_cmake_path MsysPath ResultingPath)
    string(REGEX REPLACE "^/([a-zA-Z])/" "\\1:/" ${ResultingPath} "${MsysPath}")
endmacro()

msys_to_cmake_path("$ENV{CPP3DS}" CPP3DS)
msys_to_cmake_path("$ENV{GL3DS}" GL3DS)

msys_to_cmake_path("$ENV{DEVKITPRO}" DEVKITPRO)
if(NOT IS_DIRECTORY ${DEVKITPRO})
    message(FATAL_ERROR "Please set DEVKITPRO in your environment")
endif()

msys_to_cmake_path("$ENV{DEVKITARM}" DEVKITARM)
if(NOT IS_DIRECTORY ${DEVKITARM})
    message(FATAL_ERROR "Please set DEVKITARM in your environment")
endif()

find_package(CTRULIB)


##############
## 3DSXTOOL ##
##############
if(NOT _3DSXTOOL)
    # message(STATUS "Looking for 3dsxtool...")
    find_program(_3DSXTOOL 3dsxtool ${DEVKITARM}/bin)
    if(_3DSXTOOL)
        message(STATUS "3dsxtool: ${_3DSXTOOL} - found")
    else()
        message(WARNING "3dsxtool - not found")
    endif()
endif()


##############
## SMDHTOOL ##
##############
if(NOT SMDHTOOL)
    # message(STATUS "Looking for smdhtool...")
    find_program(SMDHTOOL smdhtool ${DEVKITARM}/bin)
    if(SMDHTOOL)
        message(STATUS "smdhtool: ${SMDHTOOL} - found")
    else()
        message(WARNING "smdhtool - not found")
    endif()
endif()

################
## BANNERTOOL ##
################
if(NOT BANNERTOOL)
    # message(STATUS "Looking for bannertool...")
    find_program(BANNERTOOL bannertool ${DEVKITARM}/bin)
    if(BANNERTOOL)
        message(STATUS "bannertool: ${BANNERTOOL} - found")
    else()
        message(WARNING "bannertool - not found")
    endif()
endif()

set(FORCE_SMDHTOOL FALSE CACHE BOOL "Force the use of smdhtool instead of bannertool")

#############
## MAKEROM ##
#############
if(NOT MAKEROM)
    # message(STATUS "Looking for makerom...")
    find_program(MAKEROM makerom ${DEVKITARM}/bin)
    if(MAKEROM)
        message(STATUS "makerom: ${MAKEROM} - found")
    else()
        message(WARNING "makerom - not found")
    endif()
endif()

#############
##  STRIP  ##
#############
if(NOT STRIP)
    # message(STATUS "Looking for strip...")
    find_program(STRIP arm-none-eabi-strip ${DEVKITARM}/bin)
    if(STRIP)
        message(STATUS "strip: ${STRIP} - found")
    else()
        message(WARNING "strip - not found")
    endif()
endif()

###############
##  3DSLINK  ##
###############
if(NOT _3DSLINK)
    # message(STATUS "Looking for 3dslink...")
    find_program(_3DSLINK 3dslink ${DEVKITARM}/bin)
    if(_3DSLINK)
        message(STATUS "3dslink: ${_3DSLINK} - found")
    else()
        message(WARNING "3dslink - not found")
    endif()
endif()


#############
## PICASSO ##
#############
if(NOT PICASSO_EXE)
    message(STATUS "Looking for Picasso...")
    find_program(PICASSO_EXE picasso ${DEVKITARM}/bin)
    if(PICASSO_EXE)
        message(STATUS "Picasso: ${PICASSO_EXE} - found")
        set(SHADER_AS picasso CACHE STRING "The shader assembler to be used. Allowed values are 'picasso' or 'nihstro'")
    else()
        message(WARNING "Picasso - not found")
    endif()
endif()


#############
## NIHSTRO ##
#############

if(NOT NIHSTRO_AS)
    message(STATUS "Looking for nihstro...")
    find_program(NIHSTRO_AS nihstro-assemble ${DEVKITARM}/bin)
    if(NIHSTRO_AS)
        message(STATUS "nihstro: ${NIHSTRO_AS} - found")
        set(SHADER_AS nihstro CACHE STRING "The shader assembler to be used. Allowed values are 'picasso' or 'nihstro'")
    else()
        message(STATUS "nihstro - not found")
    endif()
endif()


function(compile_shaders output)
    if(SHADER_AS)
        foreach(shader ${ARGN})
            get_filename_component(filename ${shader} NAME)
            list(APPEND ${output} "${shader}.shbin")
            add_custom_command(
                    OUTPUT ${shader}.shbin
                    COMMAND $ENV{NIHSTRO}/nihstro-assemble ${shader} -o ${shader}.shbin
                    DEPENDS ${shader}
                    COMMENT "Compiling shader ${filename}"
            )
        endforeach(shader)
    else()
        message(ERROR "Called compile_shaders() without any compiler detected.")
    endif()
    set(${output} ${${output}} PARENT_SCOPE)
endfunction()


function(compile_core_shaders output directory)
	string(REGEX REPLACE "/+$" "" directory "${directory}") # Remove trailing slash
	if(SHADER_AS)
		foreach(shader ${ARGN})
			get_filename_component(filename ${shader} NAME)
			get_filename_component(dir ${shader} DIRECTORY)
			string(REPLACE ${directory} "" newdir ${dir})
			file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}${newdir})
			list(APPEND ${output} "${CMAKE_CURRENT_BINARY_DIR}${newdir}/${filename}")
			add_custom_command(
				OUTPUT ${CMAKE_CURRENT_BINARY_DIR}${newdir}/${filename}
				COMMAND $ENV{NIHSTRO}/nihstro-assemble ${shader} -o ${CMAKE_CURRENT_BINARY_DIR}${newdir}/${filename}
				DEPENDS ${shader}
				COMMENT "Compiling shader ${filename}"
			)
		endforeach(shader)
	else()
		message(ERROR "Called compile_shaders() without any compiler detected.")
	endif()
	set(${output} ${${output}} PARENT_SCOPE)
endfunction()


macro(compile_resources name directory output)
	add_custom_command(
		OUTPUT ${output}
		COMMAND python ${CPP3DS}/scripts/res_compile.py -o ${output} -d ${directory} -d ${CMAKE_CURRENT_BINARY_DIR} -n ${name} ${ARGN}
		DEPENDS ${ARGN}
		COMMENT "Generating ${name}"
	)
endmacro()


function(__add_smdh target APP_TITLE APP_DESCRIPTION APP_AUTHOR APP_ICON)
    if(BANNERTOOL AND NOT FORCE_SMDHTOOL)
        set(__SMDH_COMMAND ${BANNERTOOL} makesmdh -s ${APP_TITLE} -l ${APP_DESCRIPTION}  -p ${APP_AUTHOR} -i ${APP_ICON} -o ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${target})
    else()
        set(__SMDH_COMMAND ${SMDHTOOL} --create ${APP_TITLE} ${APP_DESCRIPTION} ${APP_AUTHOR} ${APP_ICON} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${target})
    endif()
    add_custom_command( OUTPUT ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${target}
            COMMAND ${__SMDH_COMMAND}
            WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
            DEPENDS ${APP_ICON}
            VERBATIM
    )
endfunction()


function(add_3dsx_target target)
    get_filename_component(target_we ${target} NAME_WE)
    if((NOT (${ARGC} GREATER 1 AND "${ARGV1}" STREQUAL "NO_SMDH") ) OR (${ARGC} GREATER 3) )
        if(${ARGC} GREATER 3)
            set(APP_TITLE ${ARGV1})
            set(APP_DESCRIPTION ${ARGV2})
            set(APP_AUTHOR ${ARGV3})
        endif()
        if(${ARGC} EQUAL 5)
            set(APP_ICON ${ARGV4})
        endif()
        if(NOT APP_TITLE)
            set(APP_TITLE ${target})
        endif()
        if(NOT APP_DESCRIPTION)
            set(APP_DESCRIPTION "Built with devkitARM & libctru")
        endif()
        if(NOT APP_AUTHOR)
            set(APP_AUTHOR "Unspecified Author")
        endif()
        if(NOT APP_ICON)
            if(EXISTS ${target}.png)
                set(APP_ICON ${target}.png)
            elseif(EXISTS icon.png)
                set(APP_ICON icon.png)
            elseif(CTRULIB)
                set(APP_ICON ${CTRULIB}/default_icon.png)
            else()
                message(FATAL_ERROR "No icon found ! Please use NO_SMDH or provide some icon.")
            endif()
        endif()
        if( NOT ${target_we}.smdh)
            __add_smdh(${target_we}.smdh ${APP_TITLE} ${APP_DESCRIPTION} ${APP_AUTHOR} ${APP_ICON})
        endif()
        add_custom_command(OUTPUT ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${target_we}.3dsx
                COMMAND ${_3DSXTOOL} $<TARGET_FILE:${target}> ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${target_we}.3dsx --romfs=${PROJECT_SOURCE_DIR}/res/romfs --smdh=${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${target_we}.smdh
                DEPENDS ${target} ${ROMFS_FILES} ${SHADER_OUTPUT} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${target_we}.smdh
                VERBATIM
        )
    else()
        message(STATUS "No smdh file will be generated")
        add_custom_command(OUTPUT ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${target_we}.3dsx
                COMMAND ${_3DSXTOOL} $<TARGET_FILE:${target}> ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${target_we}.3dsx
                DEPENDS ${target}
                VERBATIM
        )
    endif()
    add_custom_target(${target_we}.3dsx ALL SOURCES ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${target_we}.3dsx)
endfunction()


function(__add_ncch_banner target IMAGE SOUND)
    if(IMAGE MATCHES ".*\\.png$")
        set(IMG_PARAM -i ${IMAGE})
    else()
        set(IMG_PARAM -ci ${IMAGE})
    endif()
    if(SOUND MATCHES ".*\\.wav$")
        set(SND_PARAM -a ${SOUND})
    else()
        set(SND_PARAM -ca ${SOUND})
    endif()
    add_custom_command(OUTPUT ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${target}
            COMMAND ${BANNERTOOL} makebanner -o ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${target} ${IMG_PARAM} ${SND_PARAM}
            WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
            DEPENDS ${IMAGE} ${SOUND}
            VERBATIM
    )
endfunction()


function(add_cia_target target RSF IMAGE SOUND )
    get_filename_component(target_we ${target} NAME_WE)
    if(${ARGC} GREATER 6)
        set(APP_TITLE ${ARGV4})
        set(APP_DESCRIPTION ${ARGV5})
        set(APP_AUTHOR ${ARGV6})
    endif()
    if(${ARGC} EQUAL 8)
        set(APP_ICON ${ARGV7})
    endif()
    if(NOT APP_TITLE)
        set(APP_TITLE ${target})
    endif()
    if(NOT APP_DESCRIPTION)
        set(APP_DESCRIPTION "Built with devkitARM & libctru")
    endif()
    if(NOT APP_AUTHOR)
        set(APP_AUTHOR "Unspecified Author")
    endif()
    if(NOT APP_ICON)
        if(EXISTS ${target}.png)
            set(APP_ICON ${target}.png)
        elseif(EXISTS icon.png)
            set(APP_ICON icon.png)
        elseif(CTRULIB)
            set(APP_ICON ${CTRULIB}/default_icon.png)
        else()
            message(FATAL_ERROR "No icon found ! Please use NO_SMDH or provide some icon.")
        endif()
    endif()
    if( NOT ${target_we}.smdh)
        __add_smdh(${target_we}.smdh ${APP_TITLE} ${APP_DESCRIPTION} ${APP_AUTHOR} ${APP_ICON})
    endif()
    __add_ncch_banner(${target_we}.bnr ${IMAGE} ${SOUND})
    add_custom_command(OUTPUT ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${target_we}.cia
            COMMAND ${STRIP} -o $<TARGET_FILE:${target}>-stripped $<TARGET_FILE:${target}>
            COMMAND ${MAKEROM}     -f cia
            -target t
            -exefslogo
            -o ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${target_we}.cia
            -elf $<TARGET_FILE:${target}>-stripped
            -rsf ${RSF}
            -banner ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${target_we}.bnr
            -icon ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${target_we}.smdh
            DEPENDS ${target} ${RSF} ${ROMFS_FILES} ${SHADER_OUTPUT} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${target_we}.bnr ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${target_we}.smdh
            WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
            VERBATIM
    )

    add_custom_target(${target_we}.cia ALL SOURCES ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${target_we}.cia)
endfunction()


macro(add_netload_target name target)
    set(NETLOAD_IP "" CACHE STRING "The ip address of the 3ds when using netload.")
    if(NETLOAD_IP)
        set(__NETLOAD_IP_OPTION -a ${NETLOAD_IP})
    endif()
    if(NOT TARGET ${target})
        message("NOT ${target}")
        set(FILE ${target})
    else()
        set(FILE ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${target}.3dsx)
    endif()
    add_custom_target(${name}
            COMMAND ${_3DSLINK} ${FILE} ${__NETLOAD_IP_OPTION}
            DEPENDS  ${FILE}
    )
endmacro()
