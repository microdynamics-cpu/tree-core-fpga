SIM_TOOL    ?= iverilog
RUN_TOOL    ?= vvp
WAVE_FORMAT ?=

MODEL :=
SIM_TOP := ${MODEL}_tb
TEST_ARGS ?= default_args

ifeq ($(TEST_ARGS), dump_fst_wave)
WAVE_FORMAT := -fst
endif
ifeq ($(TEST_ARGS), dump_vcd_wave)
WAVE_FORMAT := -vcd
endif

WARN_OPTIONS := -Wall -Winfloop -Wno-timescale
SIM_OPTIONS  := -g2012 -s $(SIM_TOP) $(WARN_OPTIONS)
# SIM_OPTIONS  := -g2012 $(WARN_OPTIONS)
INC_LIST     :=
FILE_LIST    :=
SIMV_PROG    := simv

FILE_LIST += -f ./filelist/src.f
FILE_LIST += -f ./filelist/model.f

INC_LIST += -I ./src
INC_LIST += -I ./model

comp:
	@mkdir -p build/$(SIM_TYPE)
	($(SIM_TOOL) $(SIM_OPTIONS) $(FILE_LIST) $(INC_LIST) ./tb/$(SIM_TOP).v -o $(SIMV_PROG) || exit -1) 2>&1 | tee compile.log

run: comp
	$(RUN_TOOL) -l run.log -n $(SIMV_PROG) +$(TEST_ARGS) $(WAVE_FORMAT)

clean:
	rm -rf build

.PHONY: comp run clean