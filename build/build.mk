# Report an error if the eval make function is not available.
$(eval eval_available := T)
ifneq (${eval_available},T)
    $(error This makefile only works with a Make program that supports $$(eval))
endif

# Some utility macros for manipulating awkward (whitespace) characters.
blank			:=
space			:=${blank} ${blank}

# A user defined function to recursively search for a filename below a directory
#    $1 is the directory root of the recursive search (blank for current directory).
#    $2 is the file name to search for.
define rwildcard
$(strip $(foreach d,$(wildcard ${1}*),$(call rwildcard,${d}/,${2}) $(filter $(subst *,%,%${2}),${d})))
endef

# This table is used in converting lower case to upper case.
uppercase_table:=a,A b,B c,C d,D e,E f,F g,G h,H i,I j,J k,K l,L m,M n,N o,O p,P q,Q r,R s,S t,T u,U v,V w,W x,X y,Y z,Z

# Internal macro used for converting lower case to upper case.
#   $(1) = upper case table
#   $(2) = String to convert
define uppercase_internal
$(if $(1),$$(subst $(firstword $(1)),$(call uppercase_internal,$(wordlist 2,$(words $(1)),$(1)),$(2))),$(2))
endef

# A macro for converting a string to upper case
#   $(1) = String to convert
define uppercase
$(eval uppercase_result:=$(call uppercase_internal,$(uppercase_table),$(1)))$(uppercase_result)
endef

# Convenience function for adding build definitions
# $(eval $(call add_define,FOO)) will have:
# -DFOO if $(FOO) is empty; -DFOO=$(FOO) otherwise
define add_define
    DEFINES			+=	-D$(1)$(if $(value $(1)),=$(value $(1)),)
endef

# Convenience function for adding build definitions
# $(eval $(call add_define_val,FOO,BAR)) will have:
# -DFOO=BAR
define add_define_val
    DEFINES			+=	-D$(1)=$(2)
endef

# Convenience function for verifying option has a boolean value
# $(eval $(call assert_boolean,FOO)) will assert FOO is 0 or 1
define assert_boolean
    $(if $(filter-out 0 1,$($1)),$(error $1 must be boolean))
endef

0-9 := 0 1 2 3 4 5 6 7 8 9

# Function to verify that a given option $(1) contains a numeric value
define assert_numeric
$(if $($(1)),,$(error $(1) must not be empty))
$(eval __numeric := $($(1)))
$(foreach d,$(0-9),$(eval __numeric := $(subst $(d),,$(__numeric))))
$(if $(__numeric),$(error $(1) must be numeric))
endef

define IMG_LINKERFILE
    ${BUILD_DIR}/Kopernik.ld
endef

define IMG_MAPFILE
    ${BUILD_DIR}/Kopernik.map
endef

define IMG_ELF
    ${BUILD_DIR}/Kopernik.elf
endef

define IMG_DUMP
    ${BUILD_DIR}/Kopernik.dump
endef

define IMG_BIN
    ${BUILD_PLAT}/Kopernik.bin
endef

################################################################################
# Generic image processing filters
################################################################################

################################################################################
# Auxiliary macros to build TF images from sources
################################################################################

MAKE_DEP = -Wp,-MD,$(DEP) -MT $$@ -MP


# MAKE_C_LIB builds a C source file and generates the dependency file
#   $(1) = output directory
#   $(2) = source file (%.c)
#   $(3) = library name
define MAKE_C_LIB
$(eval OBJ := $(1)/$(patsubst %.c,%.o,$(notdir $(2))))
$(eval DEP := $(patsubst %.o,%.d,$(OBJ)))

$(OBJ): $(2) $(filter-out %.d,$(MAKEFILE_LIST)) | lib$(3)_dirs
	$$(ECHO) "  CC      $$<"
	$$(Q)$$(CC) $$(CFLAGS) $(MAKE_DEP) -c $$< -o $$@

-include $(DEP)

endef

# MAKE_S_LIB builds an assembly source file and generates the dependency file
#   $(1) = output directory
#   $(2) = source file (%.S)
#   $(3) = library name
define MAKE_S_LIB
$(eval OBJ := $(1)/$(patsubst %.S,%.o,$(notdir $(2))))
$(eval DEP := $(patsubst %.o,%.d,$(OBJ)))

$(OBJ): $(2) $(filter-out %.d,$(MAKEFILE_LIST)) | lib$(3)_dirs
	$$(ECHO) "  AS      $$<"
	$$(Q)$$(AS) $$(ASFLAGS) $(MAKE_DEP) -c $$< -o $$@

-include $(DEP)

endef


# MAKE_C builds a C source file and generates the dependency file
#   $(1) = output directory
#   $(2) = source file (%.c)
#   $(3) = BL stage (2, 2u, 30, 31, 32, 33)
define MAKE_C

$(eval OBJ := $(1)/$(patsubst %.c,%.o,$(notdir $(2))))
$(eval DEP := $(patsubst %.o,%.d,$(OBJ)))
$(eval IMAGE := IMAGE_BL$(call uppercase,$(3)))
$(eval BL_CFLAGS := $(BL$(call uppercase,$(3))_CFLAGS))

$(OBJ): $(2) $(filter-out %.d,$(MAKEFILE_LIST)) | bl$(3)_dirs
	$$(ECHO) "  CC      $$<"
	$$(Q)$$(CC) $$(CFLAGS) $(MAKE_DEP) -c $$< -o $$@

-include $(DEP)

endef


# MAKE_S builds an assembly source file and generates the dependency file
#   $(1) = output directory
#   $(2) = assembly file (%.S)
#   $(3) = BL stage (2, 2u, 30, 31, 32, 33)
define MAKE_S

$(eval OBJ := $(1)/$(patsubst %.S,%.o,$(notdir $(2))))
$(eval DEP := $(patsubst %.o,%.d,$(OBJ)))
$(eval IMAGE := IMAGE_BL$(call uppercase,$(3)))

$(OBJ): $(2) $(filter-out %.d,$(MAKEFILE_LIST)) | bl$(3)_dirs
	$$(ECHO) "  AS      $$<"
	$$(Q)$$(AS) $$(ASFLAGS) -D$(IMAGE) $(MAKE_DEP) -c $$< -o $$@

-include $(DEP)

endef


# MAKE_LD generate the linker script using the C preprocessor
#   $(1) = output linker script
#   $(2) = input template
#   $(3) = BL stage (2, 2u, 30, 31, 32, 33)
define MAKE_LD

$(eval DEP := $(1).d)
$(eval IMAGE := IMAGE_BL$(call uppercase,$(3)))

$(1): $(2) $(filter-out %.d,$(MAKEFILE_LIST)) | bl$(3)_dirs
	$$(ECHO) "  PP      $$<"
	$$(Q)$$(CPP) $$(CPPFLAGS) $(TF_CFLAGS_$(ARCH)) -P -x assembler-with-cpp -D__LINKER__ $(MAKE_DEP) -D$(IMAGE) -o $$@ $$<

-include $(DEP)

endef

# MAKE_LIB_OBJS builds both C and assembly source files
#   $(1) = output directory
#   $(2) = list of source files
#   $(3) = name of the library
define MAKE_LIB_OBJS
        $(eval C_OBJS := $(filter %.c,$(2)))
        $(eval REMAIN := $(filter-out %.c,$(2)))
        $(eval $(foreach obj,$(C_OBJS),$(call MAKE_C_LIB,$(1),$(obj),$(3))))

        $(eval S_OBJS := $(filter %.S,$(REMAIN)))
        $(eval REMAIN := $(filter-out %.S,$(REMAIN)))
        $(eval $(foreach obj,$(S_OBJS),$(call MAKE_S_LIB,$(1),$(obj),$(3))))

        $(and $(REMAIN),$(error Unexpected source files present: $(REMAIN)))
endef


# MAKE_OBJS builds both C and assembly source files
#   $(1) = output directory
#   $(2) = list of source files (both C and assembly)
#   $(3) = BL stage (2, 30, 31, 32, 33)
define MAKE_OBJS
        $(eval C_OBJS := $(filter %.c,$(2)))
        $(eval REMAIN := $(filter-out %.c,$(2)))
        $(eval $(foreach obj,$(C_OBJS),$(call MAKE_C,$(1),$(obj),$(3))))

        $(eval S_OBJS := $(filter %.S,$(REMAIN)))
        $(eval REMAIN := $(filter-out %.S,$(REMAIN)))
        $(eval $(foreach obj,$(S_OBJS),$(call MAKE_S,$(1),$(obj),$(3))))

        $(and $(REMAIN),$(error Unexpected source files present: $(REMAIN)))
endef


# NOTE: The line continuation '\' is required in the next define otherwise we
# end up with a line-feed characer at the end of the last c filename.
# Also bear this issue in mind if extending the list of supported filetypes.
define SOURCES_TO_OBJS
        $(notdir $(patsubst %.c,%.o,$(filter %.c,$(1)))) \
        $(notdir $(patsubst %.S,%.o,$(filter %.S,$(1))))
endef

# Allow overriding the timestamp, for example for reproducible builds, or to
# synchronize timestamps across multiple projects.
# This must be set to a C string (including quotes where applicable).
BUILD_MESSAGE_TIMESTAMP ?= __TIME__", "__DATE__

.PHONY: libraries

# MAKE_LIB_DIRS macro defines the target for the directory where
# libraries are created
define MAKE_LIB_DIRS
        $(eval LIB_DIR    := ${BUILD_PLAT}/lib)
        $(eval ROMLIB_DIR    := ${BUILD_PLAT}/romlib)
        $(eval $(call MAKE_PREREQ_DIR,${LIB_DIR},${BUILD_PLAT}))
        $(eval $(call MAKE_PREREQ_DIR,${ROMLIB_DIR},${BUILD_PLAT}))
        $(eval $(call MAKE_PREREQ_DIR,${LIBWRAPPER_DIR},${BUILD_PLAT}))
endef

# MAKE_TARGET macro defines the targets and options to build each BL image.
# Arguments:
#   $(1) = BL stage (2, 2u, 30, 31, 32, 33)
#   $(2) = FIP command line option (if empty, image will not be included in the FIP)
#   $(3) = FIP prefix (optional) (if FWU_, target is fwu_fip instead of fip)
define MAKE_TARGET
        $(eval BUILD_DIR  := ${BUILD_PLAT}/Kopernik)
        $(eval SOURCES    := $(TARGET_COMMON_SOURCES) $(PLAT_COMMON_SOURCES) $(PLAT_SOURCES))
        $(eval OBJS       := $(addprefix $(BUILD_DIR)/,$(call SOURCES_TO_OBJS,$(SOURCES))))
        $(eval LINKERFILE := $(call IMG_LINKERFILE,$(1)))
        $(eval MAPFILE    := $(call IMG_MAPFILE,$(1)))
        $(eval ELF        := $(call IMG_ELF,$(1)))
        $(eval DUMP       := $(call IMG_DUMP,$(1)))
        $(eval BIN        := $(call IMG_BIN,$(1)))
        $(eval BL_LINKERFILE := $(BL$(call uppercase,$(1))_LINKERFILE))
        # We use sort only to get a list of unique object directory names.
        # ordering is not relevant but sort removes duplicates.
        $(eval TEMP_OBJ_DIRS := $(sort $(dir ${OBJS} ${LINKERFILE})))
        # The $(dir ) function leaves a trailing / on the directory names
        # Rip off the / to match directory names with make rule targets.
        $(eval OBJ_DIRS   := $(patsubst %/,%,$(TEMP_OBJ_DIRS)))

# Create generators for object directory structure

$(eval $(call MAKE_PREREQ_DIR,${BUILD_DIR},${BUILD_PLAT}))

$(eval $(foreach objd,${OBJ_DIRS},$(call MAKE_PREREQ_DIR,${objd},${BUILD_DIR})))

.PHONY : Kopernik_dirs

Kopernik_dirs: | ${OBJ_DIRS}

$(eval $(call MAKE_OBJS,$(BUILD_DIR),$(SOURCES),$(1)))
$(eval $(call MAKE_LD,$(LINKERFILE),$(BL_LINKERFILE),$(1)))

$(ELF): $(OBJS) $(LINKERFILE) | Kopernik_dirs
	$$(ECHO) "  LD      $$@"
	@echo 'const char build_message[] = "Built : "$(BUILD_MESSAGE_TIMESTAMP); \
	       const char version_string[] = "${VERSION_STRING}";' | \
		$$(CC) $$(CFLAGS) -xc -c - -o $(BUILD_DIR)/build_message.o
	$$(Q)$$(LD) -o $$@ $$(LDFLAGS) -Wl,-Map=$(MAPFILE) \
		-Wl,-T$(LINKERFILE) $(BUILD_DIR)/build_message.o \
		$(OBJS) $(LDPATHS) $(LDLIBS)

$(DUMP): $(ELF)
	$${ECHO} "  OD      $$@"
	$${Q}$${OD} -dx $$< > $$@

$(BIN): $(ELF)
	$${ECHO} "  BIN     $$@"
	$$(Q)$$(OC) -O binary $$< $$@
	@${ECHO_BLANK_LINE}
	@echo "Built $$@ successfully"
	@${ECHO_BLANK_LINE}

.PHONY: Kopernik
Kopernik: $(BIN) $(DUMP)

all: Kopernik

endef
