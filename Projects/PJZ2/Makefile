# Things that can be overridden on command line, eg "make demo DEBUG=1"
DEBUG	= 0
RUNDEMO	= 1
VERBOSE	= 1

NAME	= PJZ-PlanetDiscoBalls
EXE	=$(NAME)
EXEUNPACKED=$(NAME)Unpacked
#TARGET	= runa500
TARGET	= runaros

CONFIG	= +kick13
OBJDIR	= Build
RELDIR	= Release
OUTDIR	= dh0
ASSETSIN= Assets
ASSETSOUT= AssetsConverted
SPLMOD	= SplitMod

# Setup target specific values
ifeq ($(MAKECMDGOALS),)
$(error Please specify target of 'gendemo','genvector', 'genstretchvert', 'run','clean','cleandata','cleanobj'.)
endif

# Prepare paths on windows, note space after \ as \\ is no good
ifeq ($(OS),Windows_NT)
	CONFIG:=${CONFIG}_win
	RM:=del /F /Q
	PATHSEP2:=\ 
	PATHSEP:=$(strip $(PATHSEP2))
else
	RM:=rm -f 
	PATHSEP:=/
endif

ifeq ($(RUNDEMO),1)
	_RUNDEMOCMD=$(TARGET) "$(abspath $(OUTDIR)\$(EXE))"
	RUNDEMOCMD:=$(subst /,$(PATHSEP),$(_RUNDEMOCMD))
else
	RUNDEMOCMD:=
endif


CC	= vc
COPTS	= -O1
AS	= vasmm68k_mot
ASOBJ	= -Fvobj
ASBIN	= -Fbin
ASOPT	= -m68000 -opt-speed -opt-lsl -opt-pea -opt-mul -opt-div -opt-movem -Fhunk -kick1hunks -x -nowarn=62 -nomsg=2054 -nomsg=2050
#ASOPT	= -m68000 -devpac -opt-speed -opt-lsl -opt-pea -opt-mul -opt-div -opt-movem -Fhunk -kick1hunks -nowarn=62 -nomsg=2054 -nomsg=2050 -x
ASINC	= -I Include
ASDEP	= -depend=make
LD	= vlink
LDOPT	= -bamigahunk -Bstatic -k

ifneq (,$(findstring gendemo,$(MAKECMDGOALS)))
	ASOPT += -D_INTROWRAPPER=1
#	PACKCMD:=COPY /Y "$(OUTDIR)\$(EXEUNPACKED)" "$(OUTDIR)\$(EXE)"
#	PACKCMD:=cranker -f "$(OUTDIR)\$(EXEUNPACKED)" -o "$(OUTDIR)\$(EXE)" -d progress -tf "ADF\IntroDepackText.txt"
	PACKCMD:=shrinkler "$(OUTDIR)\$(EXEUNPACKED)" "$(OUTDIR)\$(EXE)" -5 --flash dff180 --text "Loading $(NAME). Please wait..." --overlap --no-progress
else
	ASOPT += -D_INTROWRAPPER=0
	PACKCMD:=COPY /Y "$(OUTDIR)\$(EXEUNPACKED)" "$(OUTDIR)\$(EXE)"
#	PACKCMD:=shrinkler "$(OUTDIR)\$(EXEUNPACKED)" "$(OUTDIR)\$(EXE)" -2 --flash dff180 --text "Loading $(NAME). Please wait..." --overlap --no-progress
endif

ifeq ($(DEBUG),0)
	ASOPT += -D_DEBUG=$(DEBUG)
	LDOPT += -s
else
	ASOPT += -linedebug -D_DEBUG=$(DEBUG)
	PACKCMD:=COPY /Y "$(OUTDIR)\$(EXEUNPACKED)" "$(OUTDIR)\$(EXE)"
endif

ifeq ($(VERBOSE),1)
	ASOPT += -showopt -D_VERBOSE=1
else
	ASOPT += -quiet -D_VERBOSE=0
endif


#########################
# Object and Data files
#########################

MODS = $(ASSETSOUT)\discotransmission.mod.trk \
	$(ASSETSOUT)\nudef.mod.trk

GFX = 	$(ASSETSOUT)\Logo1_320x153x5_inter.BPL \
	$(ASSETSOUT)\Logo2_320x184x3_inter.BPL \
	$(ASSETSOUT)\EndLogo_320x158x3_inter.BPL \
	$(ASSETSOUT)\Credit_Optic_128x96x2.SPR \
	$(ASSETSOUT)\Credit_Tecon_128x96x2.SPR \
	$(ASSETSOUT)\Credit_Antiriad_128x96x2.SPR \
	$(ASSETSOUT)\Disco_Sprite_32x32x2_4d_A_4frames.SPR \
	$(ASSETSOUT)\Disco_Sprite_32x32x2_4d_B_4frames.SPR \
	$(ASSETSOUT)\Disco_Sprite_32x32x2_4d_C_4frames.SPR \
	$(ASSETSOUT)\Dancer_Sprite_32x64x2_8frames.SPR \
	$(ASSETSOUT)\Greetz_Font_8x16x2.BPL \
	$(ASSETSOUT)\CircleFill_64x63x1.BPL \
	$(ASSETSOUT)\SquareFill_64x63x1.BPL \
	$(ASSETSOUT)\StarFill_64x63x1.BPL \

FWOBJ = $(OBJDIR)\IntroSharedData.o $(OBJDIR)\IntroFramework.o $(OBJDIR)\IntroLibrary.o \
	$(OBJDIR)\IntroPreCalc.o $(OBJDIR)\IntroPrototype.o

FWSTANDALONEOBJ = $(OBJDIR)\IntroStandalone.o $(FWOBJ)
FWWRAPPEROBJ = $(OBJDIR)\IntroWrapper.o $(FWOBJ)

VECOBJ	= $(OBJDIR)\Vector.o
TEMPLATEOBJ=$(OBJDIR)\Template.o
STRETCHVERTOBJ=$(OBJDIR)\StretchVert.o
BACKDROP1OBJ=$(OBJDIR)\Backdrop1.o
PARALINESOBJ=$(OBJDIR)\ParaLines.o
GREETZOBJ=$(OBJDIR)\Greetz.o
IBOBSOBJ=$(OBJDIR)\InterferenceBobs.o
CREDITSOBJ=$(OBJDIR)\Credits.o

DEMOOBJ	= $(STRETCHVERTOBJ) $(VECOBJ) $(BACKDROP1OBJ) $(GREETZOBJ) $(IBOBSOBJ) $(PARALINESOBJ) $(CREDITSOBJ)


#########################
# Build targets
#########################

# $@ is the target
# $< is the FIRST prereq
# $^ are all prereqs
# Always list the main .asm file first so we can use $< 

gendirectories: $(ASSETSOUT) $(OBJDIR) $(RELDIR)

gendata: gendirectories $(MODS) $(GFX)

gendemo: gendata $(FWWRAPPEROBJ) $(DEMOOBJ)
	$(LD) $(LDOPT) $(FWWRAPPEROBJ) $(DEMOOBJ) -o $(OUTDIR)\$(EXEUNPACKED)
	$(PACKCMD)

genvector: gendata $(FWSTANDALONEOBJ) $(VECOBJ)
	$(LD) $(LDOPT) $(FWSTANDALONEOBJ) $(VECOBJ) -o $(OUTDIR)\$(EXEUNPACKED)
	$(PACKCMD)

gentemplate: gendata $(FWSTANDALONEOBJ) $(TEMPLATEOBJ)
	$(LD) $(LDOPT) $(FWSTANDALONEOBJ) $(TEMPLATEOBJ) -o $(OUTDIR)\$(EXEUNPACKED)
	$(PACKCMD)

genstretchvert: gendata $(FWSTANDALONEOBJ) $(STRETCHVERTOBJ)
	$(LD) $(LDOPT) $(FWSTANDALONEOBJ) $(STRETCHVERTOBJ) -o $(OUTDIR)\$(EXEUNPACKED)
	$(PACKCMD)

genbackdrop1: gendata $(FWSTANDALONEOBJ) $(BACKDROP1OBJ)
	$(LD) $(LDOPT) $(FWSTANDALONEOBJ) $(BACKDROP1OBJ) -o $(OUTDIR)\$(EXEUNPACKED)
	$(PACKCMD)

genparalines: gendata $(FWSTANDALONEOBJ) $(PARALINESOBJ)
	$(LD) $(LDOPT) $(FWSTANDALONEOBJ) $(PARALINESOBJ) -o $(OUTDIR)\$(EXEUNPACKED)
	$(PACKCMD)

gengreetz: gendata $(FWSTANDALONEOBJ) $(GREETZOBJ)
	$(LD) $(LDOPT) $(FWSTANDALONEOBJ) $(GREETZOBJ) -o $(OUTDIR)\$(EXEUNPACKED)
	$(PACKCMD)

genibobs: gendata $(FWSTANDALONEOBJ) $(IBOBSOBJ)
	$(LD) $(LDOPT) $(FWSTANDALONEOBJ) $(IBOBSOBJ) -o $(OUTDIR)\$(EXEUNPACKED)
	$(PACKCMD)

genending: gendata $(FWSTANDALONEOBJ) $(ENDINGOBJ)
	$(LD) $(LDOPT) $(FWSTANDALONEOBJ) $(ENDINGOBJ) -o $(OUTDIR)\$(EXEUNPACKED)
	$(PACKCMD)

gencredits: gendata $(FWSTANDALONEOBJ) $(CREDITSOBJ)
	$(LD) $(LDOPT) $(FWSTANDALONEOBJ) $(CREDITSOBJ) -o $(OUTDIR)\$(EXEUNPACKED)
	$(PACKCMD)

genrel: genadf genzip

genadf:
	copy "ADF\Demo.readme" "$(OBJDIR)\$(NAME).readme" /Y
	copy "ADF\Demo.readme.info" "$(OBJDIR)\$(NAME).readme.info" /Y
	copy "ADF\Demo.info" "$(OBJDIR)\$(NAME).info" /Y
	-mkdir "$(RELDIR)\ADF"
	-adfcreate -f 0 -l $(NAME) "$(OBJDIR)\$(NAME).adf"
	-adfinst "$(OBJDIR)\$(NAME).adf" -i
	-adfcopy "$(OBJDIR)\$(NAME).adf" "$(OUTDIR)\$(EXE)" /
	-adfmakedir "$(OBJDIR)\$(NAME).adf" s
	-adfcopy "$(OBJDIR)\$(NAME).adf" "ADF\s\Startup-Sequence" s
	-adfcopy "$(OBJDIR)\$(NAME).adf" "$(OBJDIR)\$(NAME).readme" /
	-adfcopy "$(OBJDIR)\$(NAME).adf" "ADF\file_id.diz" /
	copy "$(OBJDIR)\$(NAME).adf" "$(RELDIR)\ADF" /Y
	copy "$(OBJDIR)\$(NAME).readme" "$(RELDIR)\ADF" /Y
	copy "ADF\file_id.diz" "$(RELDIR)\ADF" /Y
	7z.exe a -tzip -mx=9 "$(RELDIR)\$(NAME)-ADF.zip" ".\$(RELDIR)\ADF\*"

genzip:
	copy "ADF\Demo.readme" "$(OBJDIR)\$(NAME).readme" /Y
	copy "ADF\Demo.readme.info" "$(OBJDIR)\$(NAME).readme.info" /Y
	copy "ADF\Demo.info" "$(OBJDIR)\$(NAME).info" /Y
	-mkdir "$(RELDIR)\LHA"
	copy "$(OUTDIR)\$(EXE)" "$(RELDIR)\LHA" /Y
	copy "$(OBJDIR)\$(EXE).readme" "$(RELDIR)\LHA" /Y
	copy "ADF\file_id.diz" "$(RELDIR)\LHA" /Y
	cd /d "$(RELDIR)\LHA" && lha.exe a -o5 "..\$(NAME)-FILES.lha" *


run:
	$(RUNDEMOCMD)

clean: cleandata cleanobj cleanrel

cleanobj:
	-rmdir /s /q $(OBJDIR)
#	-$(RM) $(OBJDIR)\*.o
	-$(RM) $(OUTDIR)\$(EXE)
	-$(RM) $(OUTDIR)\$(EXEUNPACKED)
	
cleandata:
	-$(RM) $(ASSETSOUT)\*.*
#	-$(RM) $(subst /,$(PATHSEP),$(EXE))
#	-$(RM) $(subst /,$(PATHSEP),$(EXEUNPACKED))

cleanrel:
	-rmdir /s /q $(RELDIR)


#########################
# Release files (adf, archive etc)
#########################

$(RELDIR):
	-mkdir $(RELDIR)


#########################
# Assets 
#########################

$(ASSETSOUT):
	-mkdir $(ASSETSOUT)

$(ASSETSOUT)\\%.mod: $(ASSETSIN)\%.mod
	copy /Y $< $(ASSETSOUT)\*.*

$(ASSETSOUT)\\%.mod.trk: $(ASSETSOUT)\\%.mod
	$(SPLMOD) "$<"

# Use .nrv2s as the base, but just use every other compressor on the same file to save makefile repetition
$(ASSETSOUT)\\%.nrv2s: $(ASSETSOUT)\%
	nrv2x -q -f -es -o $@ $<
	nrv2x -q -f -er -o $<.nrv2r $<
#	lz4 -9 --no-frame-crc $< $<.lz4	
#	doynamite68k_lz -o $<.doy $<
#	cranker -q -cd -f $< -o $<.cra
#	arjbeta a -m7 -jm $<.arj $<
#	arj2raw $<.arj $(notdir $<) $<.am7
#	-$(RM) $<.arj
#	rnc_pack_x86.exe p $< $<.rnc1 -m=1
#	rnc_pack_x86.exe p $< $<.rnc2 -m=2
#	packfire -l $< $<.pkl
#	packfire -t $< $<.pkt
#	shrinkler -3 -d -p $< $<.shr	

$(ASSETSOUT)\Logo1_320x153x5_inter.BPL: $(ASSETSIN)\Logo1_320x256x5.png
	kingcon $< $(basename $@) -format=5 -w=320 -h=153 -y=58 -interleaved -rawpalette -ftpalette=dc.w

$(ASSETSOUT)\Logo2_320x184x3_inter.BPL: $(ASSETSIN)\Logo2_320x256x3.png
	kingcon $< $(basename $@) -format=3 -w=320 -h=184 -y=53 -interleaved -rawpalette -ftpalette=dc.w

$(ASSETSOUT)\EndLogo_320x158x3_inter.BPL: $(ASSETSIN)\Logo3_320x256x3.png
	kingcon $< $(basename $@) -format=3 -w=320 -h=158 -y=52 -interleaved -rawpalette -ftpalette=dc.w

$(ASSETSOUT)\Credit_Optic_128x96x2.SPR: $(ASSETSIN)\Credit_Optic_128x96x2.png
	kingcon $< $(basename $@) -format=s16 -x=0 -y=0 -w=128 -h=96

$(ASSETSOUT)\Credit_Tecon_128x96x2.SPR: $(ASSETSIN)\Credit_Tecon_128x96x2.png
	kingcon $< $(basename $@) -format=s16 -x=0 -y=0 -w=128 -h=96

$(ASSETSOUT)\Credit_Antiriad_128x96x2.SPR: $(ASSETSIN)\Credit_Antiriad_128x96x2.png
	kingcon $< $(basename $@) -format=s16 -x=0 -y=0 -w=128 -h=96

$(ASSETSOUT)\Disco_Sprite_32x32x2_4d_A_4frames.SPR: $(ASSETSIN)\Disco_Sprite_32x32x2_4d_A_0.png
	kingcon $< $(basename $@) -format=s16 -anim=4 -x=0 -y=0 -w=31 -h=31

$(ASSETSOUT)\Disco_Sprite_32x32x2_4d_B_4frames.SPR: $(ASSETSIN)\Disco_Sprite_32x32x2_4d_B_0.png
	kingcon $< $(basename $@) -format=s16 -anim=4 -x=0 -y=0 -w=31 -h=31

$(ASSETSOUT)\Disco_Sprite_32x32x2_4d_C_4frames.SPR: $(ASSETSIN)\Disco_Sprite_32x32x2_4d_C_0.png
	kingcon $< $(basename $@) -format=s16 -anim=4 -x=0 -y=0 -w=31 -h=31

$(ASSETSOUT)\Dancer_Sprite_32x64x2_8frames.SPR: $(ASSETSIN)\Dancer_Sprite_32x64x2_0.png
	kingcon $< $(basename $@) -format=s16 -anim=8 -x=0 -y=0 -w=32 -h=64

$(ASSETSOUT)\Greetz_Font_8x16x2.BPL: $(ASSETSIN)\Font_PJZ_01_8x16x2_3Col.png
	kingcon $< $(basename $@) -format=2 -proportionalfont "ABCDEFGHIJKLMNOPQRST\nUWXYZabcdefghijklmno\npqrstuvwxyz12345678\n9()!?@.,'-+=/\\:;~#_^\n&V0" -x=0 -y=0 -h=16 -gap=0 -interleaved -ftfont=dc.b -ftbob=dc.w -rawpalette -ftpalette=dc.w

$(ASSETSOUT)\CircleFill_64x63x1.BPL: $(ASSETSIN)\CircleFill_64x63x1.png
	kingcon $< $(basename $@) -format=1 -w=64 -h=63

$(ASSETSOUT)\SquareFill_64x63x1.BPL: $(ASSETSIN)\SquareFill_64x63x1.png
	kingcon $< $(basename $@) -format=1 -w=64 -h=63

$(ASSETSOUT)\StarFill_64x63x1.BPL: $(ASSETSIN)\StarFill_64x63x1.png
	kingcon $< $(basename $@) -format=1 -w=64 -h=63



#########################
# Code
#########################

$(OBJDIR):
	-mkdir $(OBJDIR)

$(OBJDIR)\IntroWrapper.o: IntroWrapper.asm IntroConfig.i
	$(AS) $(ASOBJ) $(ASOPT) $(ASINC) -o $@ $<

$(OBJDIR)\IntroPreCalc.o: PreCalcMinimal\IntroPreCalc.asm IntroConfig.i $(MODS) $(GFX)
	$(AS) $(ASOBJ) $(ASOPT) $(ASINC) -o $@ $<

$(OBJDIR)\IntroSharedData.o: IntroSharedData.asm IntroConfig.i $(MODS) $(GFX)
	$(AS) $(ASOBJ) $(ASOPT) $(ASINC) -o $@ $<

$(OBJDIR)\IntroLibrary.o: Framework\IntroLibrary.asm IntroConfig.i
	$(AS) $(ASOBJ) $(ASOPT) $(ASINC) -o $@ $<

$(OBJDIR)\IntroStandalone.o: Framework\IntroStandalone.asm IntroConfig.i
	$(AS) $(ASOBJ) $(ASOPT) $(ASINC) -o $@ $<

$(OBJDIR)\IntroFramework.o: Framework\IntroFramework.asm IntroConfig.i
	$(AS) $(ASOBJ) $(ASOPT) $(ASINC) -o $@ $<

$(OBJDIR)\IntroPrototype.o: Framework\IntroPrototype.asm IntroConfig.i
	$(AS) $(ASOBJ) $(ASOPT) $(ASINC) -o $@ $<

$(OBJDIR)\Vector.o: Vector\Vector.asm Vector\Script.asm \
	Vector\SectionData_PublicData.asm Vector\SectionData_ChipData.asm \
	Vector\Obj_Icosahedron20.i \
	IntroConfig.i $(MODS) $(GFX)
	$(AS) $(ASOBJ) $(ASOPT) $(ASINC) -o $@ $<

$(OBJDIR)\Template.o: Template\Template.asm Template\Script.asm \
	Template\SectionData_PublicData.asm Template\SectionData_ChipData.asm \
	IntroConfig.i $(MODS) $(GFX)
	$(AS) $(ASOBJ) $(ASOPT) $(ASINC) -o $@ $<

$(OBJDIR)\StretchVert.o: StretchVert\StretchVert.asm StretchVert\Script.asm \
	StretchVert\SectionData_PublicData.asm StretchVert\SectionData_ChipData.asm \
	IntroConfig.i $(MODS) $(GFX)
	$(AS) $(ASOBJ) $(ASOPT) $(ASINC) -o $@ $<

$(OBJDIR)\Backdrop1.o: Backdrop1\Backdrop1.asm Backdrop1\Script.asm \
	Backdrop1\SectionData_PublicData.asm Backdrop1\SectionData_ChipData.asm \
	IntroConfig.i $(MODS) $(GFX)
	$(AS) $(ASOBJ) $(ASOPT) $(ASINC) -o $@ $<

$(PARALINESOBJ): ParaLines\ParaLines.asm ParaLines\Script.asm \
	ParaLines\SectionData_PublicData.asm ParaLines\SectionData_ChipData.asm \
	IntroConfig.i $(MODS) $(GFX)
	$(AS) $(ASOBJ) $(ASOPT) $(ASINC) -o $@ $<

$(GREETZOBJ): Greetz\Greetz.asm Greetz\Script.asm \
	Greetz\SectionData_PublicData.asm Greetz\SectionData_ChipData.asm \
	IntroConfig.i $(MODS) $(GFX)
	$(AS) $(ASOBJ) $(ASOPT) $(ASINC) -o $@ $<

$(IBOBSOBJ): InterferenceBobs\InterferenceBobs.asm InterferenceBobs\Script.asm \
	InterferenceBobs\SectionData_PublicData.asm InterferenceBobs\SectionData_ChipData.asm \
	IntroConfig.i $(MODS) $(GFX)
	$(AS) $(ASOBJ) $(ASOPT) $(ASINC) -o $@ $<

$(CREDITSOBJ): Credits\Credits.asm Credits\Script.asm \
	Credits\SectionData_PublicData.asm Credits\SectionData_ChipData.asm \
	IntroConfig.i $(MODS) $(GFX)
	$(AS) $(ASOBJ) $(ASOPT) $(ASINC) -o $@ $<