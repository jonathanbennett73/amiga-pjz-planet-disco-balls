;-------------------T-----------T-----------------T---------T---------------

ahxInitCIA          = 0*4
ahxInitPlayer       = 1*4
ahxInitModule       = 2*4
ahxInitSubSong      = 3*4
ahxInterrupt        = 4*4
ahxStopSong         = 5*4
ahxKillPlayer       = 6*4
ahxKillCIA          = 7*4
ahxNextPattern      = 8*4       ;implemented, although no-one requested it :-)
ahxPrevPattern      = 9*4       ;implemented, although no-one requested it :-)

ahxBSS_P            = 10*4      ;pointer to ahx's public (fast) memory block
ahxBSS_C            = 11*4      ;pointer to ahx's explicit chip memory block
ahxBSS_Psize        = 12*4      ;size of public memory (intern use only!)
ahxBSS_Csize        = 13*4      ;size of chip memory (intern use only!)
ahxModule           = 14*4      ;pointer to ahxModule after InitModule
ahxIsCIA            = 15*4      ;byte flag (using ANY (intern/own) cia?)
ahxTempo            = 16*4      ;word to cia tempo (normally NOT needed to xs)

ahx_pExternalTiming = 0         ;byte, offset to public memory block
ahx_pMainVolume     = 1         ;byte, offset to public memory block
ahx_pSubsongs       = 2         ;byte, offset to public memory block
ahx_pSongEnd        = 3         ;flag, offset to public memory block
ahx_pPlaying        = 4         ;flag, offset to public memory block
ahx_pVoice0Temp     = 14        ;struct, current Voice 0 values
ahx_pVoice1Temp     = 246       ;struct, current Voice 1 values
ahx_pVoice2Temp     = 478       ;struct, current Voice 2 values
ahx_pVoice3Temp     = 710       ;struct, current Voice 3 values

ahx_pvtTrack        = 0         ;byte          (relative to ahx_pVoiceXTemp!)
ahx_pvtTranspose    = 1         ;byte          (relative to ahx_pVoiceXTemp!)
ahx_pvtNextTrack    = 2         ;byte          (relative to ahx_pVoiceXTemp!)
ahx_pvtNextTranspose= 3         ;byte          (relative to ahx_pVoiceXTemp!)
ahx_pvtADSRVolume   = 4         ;word, 0..64:8 (relative to ahx_pVoiceXTemp!)
ahx_pvtAudioPointer = 92        ;pointer       (relative to ahx_pVoiceXTemp!)
ahx_pvtAudioPeriod  = 100       ;word          (relative to ahx_pVoiceXTemp!)
ahx_pvtAudioVolume  = 102       ;word          (relative to ahx_pVoiceXTemp!)

; current ADSR Volume (0..64) = ahx_pvtADSR.w >> 8        (I use 24:8 32-Bit)
; ahx_pvtAudioXXX are the REAL Values passed to the hardware!