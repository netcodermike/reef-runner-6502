.setcpu "6502"

PPUCTRL   = $2000
PPUMASK   = $2001
PPUSTATUS = $2002
OAMADDR   = $2003
PPUSCROLL = $2005
PPUADDR   = $2006
PPUDATA   = $2007
PULSE0    = $4000
OAMDMA    = $4014
APUSTATUS = $4015
JOY1      = $4016
FRAMECTR  = $4017
OAM       = $0200

BUTTON_A     = $80
BUTTON_START = $10
BUTTON_UP    = $08
BUTTON_DOWN  = $04
BUTTON_LEFT  = $02
BUTTON_RIGHT = $01

TITLE    = 0
PADDLE   = 1
RIDE     = 2
WIPEOUT  = 3
COMPLETE = 4

MSG_TITLE   = 0
MSG_PADDLE  = 1
MSG_TAKEOFF = 2
MSG_EARLY   = 3
MSG_LATE    = 4
MSG_STEER   = 5
MSG_POCKET  = 6
MSG_WIPEOUT = 7
MSG_FINISH  = 8

.segment "ZEROPAGE"
frame:         .res 1
lastFrame:     .res 1
frameReady:    .res 1
buttons:       .res 1
buttonEdges:   .res 1
state:         .res 1
messageIndex:  .res 1
feedback:      .res 1
feedbackIndex: .res 1
surferX:       .res 1
surferY:       .res 1
pocketX:       .res 1
pocketY:       .res 1
phase:         .res 1
phaseTick:     .res 1
rideTick:      .res 1
timeDigits:    .res 2
scoreDigits:   .res 4
bestDigits:    .res 4
streakTick:    .res 1
spawnTick:     .res 1
reefPattern:   .res 1
reefX:         .res 2
reefY:         .res 2
reefSpeed:     .res 1
soundTick:     .res 1
tilePointer:   .res 2
screenRow:     .res 1
spriteX:       .res 1
spriteY:       .res 1
spriteTile:    .res 1
spriteStyle:   .res 1
spriteSlot:    .res 1
savedIndex:    .res 1

.exportzp state, messageIndex, surferX, surferY, pocketX, pocketY, timeDigits, scoreDigits, bestDigits, reefX, reefY

.segment "CODE"

.proc reset
    sei
    cld
    ldx #$ff
    txs
    inx
    stx PPUCTRL
    stx PPUMASK
    stx APUSTATUS
    stx $4010
    lda #$40
    sta FRAMECTR
    bit PPUSTATUS
@firstVblank:
    bit PPUSTATUS
    bpl @firstVblank
    lda #0
@clear:
    sta $0000,x
    lda #$ff
    sta OAM,x
    lda #0
    inx
    bne @clear
@secondVblank:
    bit PPUSTATUS
    bpl @secondVblank

    jsr draw_background
    jsr begin_paddle
    lda #TITLE
    sta state
    sta messageIndex
    jsr draw_sprites
    jsr update_hud
    lda #$88
    sta PPUCTRL
    lda #$1e
    sta PPUMASK
@main:
    lda frame
    cmp lastFrame
    beq @main
    sta lastFrame
    jsr read_pad
    jsr update_game
    jsr draw_sprites
    lda #1
    sta frameReady
    jmp @main
.endproc

.proc nmi
    pha
    txa
    pha
    tya
    pha
    lda frameReady
    beq @done
    lda #0
    sta frameReady
    sta OAMADDR
    lda #>OAM
    sta OAMDMA
    jsr update_hud
@done:
    inc frame
    pla
    tay
    pla
    tax
    pla
    rti
.endproc

.proc irq
    rti
.endproc

.proc read_pad
    lda buttons
    pha
    lda #1
    sta JOY1
    lsr a
    sta JOY1
    sta buttons
    ldx #8
@bit:
    lda JOY1
    lsr a
    rol buttons
    dex
    bne @bit
    pla
    eor #$ff
    and buttons
    sta buttonEdges
    rts
.endproc

.proc begin_paddle
    lda #PADDLE
    sta state
    lda #MSG_PADDLE
    sta messageIndex
    lda #68
    sta surferX
    lda #122
    sta surferY
    sta pocketY
    lda #224
    sta pocketX
    lda #3
    sta timeDigits
    lda #0
    sta timeDigits+1
    sta reefX
    sta reefX+1
    sta feedback
    sta scoreDigits
    sta scoreDigits+1
    sta scoreDigits+2
    sta scoreDigits+3
    sta soundTick
    sta APUSTATUS
    rts
.endproc

.proc update_game
    lda soundTick
    beq @input
    dec soundTick
    bne @input
    lda #0
    sta APUSTATUS
@input:
    lda buttonEdges
    and #BUTTON_START
    beq @state
    jmp begin_paddle
@state:
    lda state
    cmp #PADDLE
    beq @paddle
    cmp #RIDE
    beq @ride
    ; Keep the swell moving behind the title while the surfer waits.
    cmp #TITLE
    bne @done
    jsr move_incoming_wave
@done:
    rts
@paddle:
    jmp update_paddle
@ride:
    jmp update_ride
.endproc

; Carry is set while the visible bracket overlaps the takeoff window.
.proc takeoff_window
    lda pocketX
    cmp #54
    bcc @no
    cmp #83
    bcs @no
    sec
    rts
@no:
    clc
    rts
.endproc

.proc move_incoming_wave
    lda pocketX
    sec
    sbc #2
    cmp #28
    bcs @store
    lda #224
@store:
    sta pocketX
    rts
.endproc

.proc update_paddle
    lda buttonEdges
    and #BUTTON_A
    beq @advance
    jsr takeoff_window
    bcc @missed
    jmp begin_ride
@missed:
    lda #MSG_LATE
    ldx pocketX
    cpx #54
    bcc @feedback
    lda #MSG_EARLY
@feedback:
    sta feedbackIndex
    lda #36
    sta feedback
    lda #200
    ldx #6
    jsr play_note
@advance:
    jsr move_incoming_wave
    jsr takeoff_window
    bcc @noWindow
    lda #MSG_TAKEOFF
    sta messageIndex
    rts
@noWindow:
    lda #MSG_PADDLE
    ldx feedback
    beq @show
    dec feedback
    lda feedbackIndex
@show:
    sta messageIndex
    rts
.endproc

.proc begin_ride
    lda #RIDE
    sta state
    lda #MSG_POCKET
    sta messageIndex
    lda #0
    sta phaseTick
    sta phase
    sta rideTick
    sta streakTick
    sta reefPattern
    lda #96
    sta spawnTick
    lda #2
    sta reefSpeed
    lda #86
    ldx #18
    jmp play_note
.endproc

.proc update_ride
    jsr steer
    inc phaseTick
    lda phaseTick
    and #3
    bne @score
    inc phase
    lda phase
    and #63
    tax
    lda pocket_path_x,x
    sta pocketX
    lda pocket_path_y,x
    sta pocketY
@score:
    jsr score_pocket
    jsr advance_reef
    lda state
    cmp #RIDE
    bne @done
    inc rideTick
    lda rideTick
    cmp #60
    bcc @done
    lda #0
    sta rideTick
    lda timeDigits+1
    beq @borrow
    dec timeDigits+1
    jmp @checkTime
@borrow:
    dec timeDigits
    lda #9
    sta timeDigits+1
@checkTime:
    lda timeDigits
    cmp #1
    bcs @finishCheck
    lda #3
    sta reefSpeed
@finishCheck:
    lda timeDigits
    ora timeDigits+1
    bne @done
    lda #COMPLETE
    sta state
    lda #MSG_FINISH
    sta messageIndex
    lda #61
    ldx #27
    jmp play_note
@done:
    rts
.endproc

.proc steer
    lda buttons
    and #BUTTON_LEFT
    beq @right
    lda surferX
    cmp #26
    bcc @vertical
    dec surferX
    dec surferX
    jmp @vertical
@right:
    lda buttons
    and #BUTTON_RIGHT
    beq @vertical
    lda surferX
    cmp #230
    bcs @vertical
    inc surferX
    inc surferX
@vertical:
    lda buttons
    and #BUTTON_UP
    beq @down
    lda surferY
    cmp #86
    bcc @done
    dec surferY
    dec surferY
    rts
@down:
    lda buttons
    and #BUTTON_DOWN
    beq @done
    lda surferY
    cmp #182
    bcs @done
    inc surferY
    inc surferY
@done:
    rts
.endproc

.proc score_pocket
    lda surferX
    sec
    sbc pocketX
    clc
    adc #20
    cmp #41
    bcs @outside
    lda surferY
    sec
    sbc pocketY
    clc
    adc #15
    cmp #31
    bcs @outside
    lda #MSG_POCKET
    sta messageIndex
    inc streakTick
    lda streakTick
    cmp #8
    bcc @done
    lda #0
    sta streakTick
    jsr add_point
    lda scoreDigits+3
    bne @done
    lda #104
    ldx #6
    jsr play_note
@done:
    rts
@outside:
    lda #0
    sta streakTick
    lda #MSG_STEER
    sta messageIndex
    rts
.endproc

.proc add_point
    ldx #3
@digit:
    inc scoreDigits,x
    lda scoreDigits,x
    cmp #10
    bcc @best
    lda #0
    sta scoreDigits,x
    dex
    bpl @digit
@best:
    ldx #0
@compare:
    lda scoreDigits,x
    cmp bestDigits,x
    bcc @done
    bne @copy
    inx
    cpx #4
    bne @compare
@done:
    rts
@copy:
    lda scoreDigits,x
    sta bestDigits,x
    inx
    cpx #4
    bne @copy
    rts
.endproc

.proc advance_reef
    ldx #1
@obstacle:
    lda reefX,x
    beq @next
    sec
    sbc reefSpeed
    cmp #12
    bcs @moving
    lda #0
    sta reefX,x
    jmp @next
@moving:
    sta reefX,x
    sec
    sbc surferX
    clc
    adc #12
    cmp #25
    bcs @next
    lda reefY,x
    sec
    sbc surferY
    clc
    adc #11
    cmp #23
    bcs @next
    lda #WIPEOUT
    sta state
    lda #MSG_WIPEOUT
    sta messageIndex
    lda #230
    ldx #26
    jmp play_note
@next:
    dex
    bpl @obstacle
    dec spawnTick
    bne @done
    ldx #0
    lda reefX
    beq @spawn
    inx
    lda reefX+1
    beq @spawn
    lda #1
    sta spawnTick
    rts
@spawn:
    lda #246
    sta reefX,x
    lda reefPattern
    and #7
    tay
    lda reef_lanes,y
    sta reefY,x
    inc reefPattern
    lda #67
    ldy reefSpeed
    cpy #3
    beq @delay
    lda #88
@delay:
    sta spawnTick
@done:
    rts
.endproc

; A is the pulse timer's low byte, X is duration in frames.
.proc play_note
    stx soundTick
    pha
    lda #1
    sta APUSTATUS
    lda #$b7
    sta PULSE0
    lda #8
    sta PULSE0+1
    pla
    sta PULSE0+2
    lda #9
    sta PULSE0+3
    rts
.endproc

.proc draw_sprites
    lda #0
    sta spriteSlot
    lda state
    cmp #WIPEOUT
    beq @reef
    lda surferX
    sec
    sbc #8
    sta spriteX
    lda surferY
    sec
    sbc #8
    sta spriteY
    lda #1
    sta spriteTile
    lda #0
    sta spriteStyle
    jsr emit_quad
@reef:
    ldx #0
@reefLoop:
    lda reefX,x
    beq @nextReef
    stx savedIndex
    sec
    sbc #8
    sta spriteX
    lda reefY,x
    sec
    sbc #8
    sta spriteY
    lda #6
    sta spriteTile
    lda #2
    sta spriteStyle
    jsr emit_quad
    ldx savedIndex
@nextReef:
    inx
    cpx #2
    bne @reefLoop
    lda state
    cmp #WIPEOUT
    bcs @clear

    ; The bracket marks the moving scoring pocket. Flip one tile for each corner.
    lda pocketX
    sec
    sbc #24
    sta spriteX
    lda pocketY
    sec
    sbc #19
    sta spriteY
    lda #$0a
    sta spriteTile
    lda #3
    ldx messageIndex
    cpx #MSG_TAKEOFF
    bne @bracket
    lda #1
@bracket:
    sta spriteStyle
    jsr emit_sprite
    lda spriteX
    clc
    adc #40
    sta spriteX
    lda spriteStyle
    ora #$40
    sta spriteStyle
    jsr emit_sprite
    lda spriteY
    clc
    adc #30
    sta spriteY
    lda spriteStyle
    ora #$80
    sta spriteStyle
    jsr emit_sprite
    lda spriteX
    sec
    sbc #40
    sta spriteX
    lda spriteStyle
    and #$83
    sta spriteStyle
    jsr emit_sprite

    lda pocketX
    sec
    sbc #8
    sta spriteX
    lda pocketY
    sec
    sbc #22
    sta spriteY
    lda #$0b
    sta spriteTile
    lda #3
    sta spriteStyle
    jsr emit_sprite
@clear:
    ldx spriteSlot
    lda #$ff
@hide:
    sta OAM,x
    inx
    inx
    inx
    inx
    bne @hide
    rts
.endproc

.proc emit_quad
    jsr emit_sprite
    lda spriteX
    clc
    adc #8
    sta spriteX
    inc spriteTile
    jsr emit_sprite
    lda spriteX
    sec
    sbc #8
    sta spriteX
    lda spriteY
    clc
    adc #8
    sta spriteY
    inc spriteTile
    jsr emit_sprite
    lda spriteX
    clc
    adc #8
    sta spriteX
    inc spriteTile
    jmp emit_sprite
.endproc

.proc emit_sprite
    ldx spriteSlot
    lda spriteY
    sec
    sbc #1
    sta OAM,x
    lda spriteTile
    sta OAM+1,x
    lda spriteStyle
    sta OAM+2,x
    lda spriteX
    sta OAM+3,x
    inx
    inx
    inx
    inx
    stx spriteSlot
    rts
.endproc

.proc draw_background
    bit PPUSTATUS
    lda #$3f
    sta PPUADDR
    lda #0
    sta PPUADDR
    tay
@palette:
    lda palette,y
    sta PPUDATA
    iny
    cpy #32
    bne @palette
    lda #$20
    sta PPUADDR
    lda #0
    sta PPUADDR
    sta screenRow
@row:
    ldx screenRow
    lda row_lo,x
    sta tilePointer
    lda row_hi,x
    sta tilePointer+1
    ldy #0
@tile:
    lda (tilePointer),y
    sta PPUDATA
    iny
    cpy #32
    bne @tile
    inc screenRow
    lda screenRow
    cmp #30
    bne @row
    ldy #0
@attributes:
    lda attributes,y
    sta PPUDATA
    iny
    cpy #64
    bne @attributes
    rts
.endproc

.proc update_hud
    bit PPUSTATUS
    lda #$20
    sta PPUADDR
    lda #$3a
    sta PPUADDR
    ldx #0
@score:
    lda scoreDigits,x
    ora #$30
    sta PPUDATA
    inx
    cpx #4
    bne @score
    lda #$20
    sta PPUADDR
    lda #$5a
    sta PPUADDR
    ldx #0
@best:
    lda bestDigits,x
    ora #$30
    sta PPUDATA
    inx
    cpx #4
    bne @best
    lda #$20
    sta PPUADDR
    lda #$7b
    sta PPUADDR
    lda timeDigits
    ora #$30
    sta PPUDATA
    lda timeDigits+1
    ora #$30
    sta PPUDATA
    lda #$23
    sta PPUADDR
    lda #$62
    sta PPUADDR
    ldx messageIndex
    lda message_lo,x
    sta tilePointer
    lda message_hi,x
    sta tilePointer+1
    ldy #0
@message:
    lda (tilePointer),y
    sta PPUDATA
    iny
    cpy #28
    bne @message
    lda #0
    sta PPUSCROLL
    sta PPUSCROLL
    rts
.endproc

.segment "RODATA"

.macro text_row value
    .byte value
    .repeat 32 - .strlen(value)
        .byte $20
    .endrepeat
.endmacro

.macro message value
    .byte value
    .repeat 28 - .strlen(value)
        .byte $20
    .endrepeat
.endmacro

blank_row: text_row ""
title_row: text_row "  REEF RUNNER 6502  SCORE 0000"
point_row: text_row "  AMETHYST POINT     BEST 0000"
clock_row: text_row "  WAVE ONE           TIME  30S"
tips_row:  text_row "  START: RESET  A: TAKEOFF"

sky_row:
    .repeat 32
        .byte $0a
    .endrepeat
sun_row:
    .repeat 24
        .byte $0a
    .endrepeat
    .byte $0b
    .repeat 7
        .byte $0a
    .endrepeat
horizon_row:
    .repeat 32
        .byte $09
    .endrepeat
crest_row:
    .repeat 8
        .byte $01,$02,$03,$04
    .endrepeat
open_row:
    .repeat 8
        .byte $01,$02,$01,$01
    .endrepeat
ripple_row:
    .repeat 8
        .byte $01,$01,$02,$01
    .endrepeat
reef_row:
    .repeat 8
        .byte $01,$05,$06,$01
    .endrepeat
foam_row:
    .repeat 8
        .byte $04,$03,$01,$02
    .endrepeat
bed_row:
    .repeat 8
        .byte $08,$05,$06,$08
    .endrepeat

.define SCREEN_ROWS blank_row,title_row,point_row,clock_row,sky_row,sun_row,sky_row,horizon_row,crest_row,open_row,ripple_row,open_row,open_row,ripple_row,open_row,ripple_row,open_row,ripple_row,open_row,ripple_row,open_row,open_row,ripple_row,foam_row,reef_row,bed_row,blank_row,blank_row,tips_row,blank_row
row_lo: .lobytes SCREEN_ROWS
row_hi: .hibytes SCREEN_ROWS

attributes:
    .repeat 8
        .byte $ff
    .endrepeat
    .repeat 8
        .byte $00
    .endrepeat
    .repeat 32
        .byte $55
    .endrepeat
    .repeat 8
        .byte $fa
    .endrepeat
    .repeat 8
        .byte $ff
    .endrepeat

palette:
    .byte $0f,$03,$14,$37, $0f,$01,$1c,$3c, $0f,$01,$0c,$27, $0f,$03,$14,$30
    .byte $0f,$15,$24,$37, $0f,$06,$27,$37, $0f,$01,$0c,$16, $0f,$02,$1c,$3c

pocket_path_x:
    .byte 68,70,73,77,82,88,94,100,107,114,121,128,135,142,149,156
    .byte 163,170,176,182,187,191,194,197,198,199,199,198,196,193,189,184
    .byte 178,172,165,158,151,144,137,130,123,116,109,102,95,89,83,78
    .byte 74,71,69,67,66,65,65,65,65,65,65,66,66,67,67,68
pocket_path_y:
    .byte 122,123,124,126,128,131,134,138,142,146,150,154,157,160,162,164
    .byte 165,165,164,162,160,157,154,151,147,143,139,135,131,127,123,119
    .byte 115,111,107,104,102,100,98,97,97,98,99,101,103,106,109,112
    .byte 115,118,121,124,127,129,130,131,131,130,129,128,126,125,123,122
reef_lanes: .byte 126,166,106,150,170,115,144,102

status_title:   message "PRESS START TO PADDLE"
status_paddle:  message "WAIT FOR THE WAVE POCKET"
status_takeoff: message "TAKEOFF! PRESS A"
status_early:   message "TOO EARLY! WAIT FOR IT"
status_late:    message "MISSED IT! NEXT WAVE"
status_steer:   message "STEER INTO THE POCKET"
status_pocket:  message "IN THE POCKET"
status_wipeout: message "WIPEOUT! START TO RETRY"
status_finish:  message "CLEAN RIDE! START FOR MORE"
.define STATUS_TEXT status_title,status_paddle,status_takeoff,status_early,status_late,status_steer,status_pocket,status_wipeout,status_finish
message_lo: .lobytes STATUS_TEXT
message_hi: .hibytes STATUS_TEXT

.segment "VECTORS"
    .word nmi, reset, irq
