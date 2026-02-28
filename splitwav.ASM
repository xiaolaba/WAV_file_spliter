

; Split a WAV file to be sections
; by xiaolaba, 2026-FEB-28

; assembler : fasm 1.73.35
; https://flatassembler.net/download.php

; REF:
; https://board.flatassembler.net/topic.php?t=5900
; http://www.betamaster.us/blog/?p=439

format pe console 4.0
include 'WIN32AX.INC'

; data
  FileIn   db '20260228143912.WAV',0
  FileOut  db '20260228143912_copy.WAV',0
  WAV      db '20260228143912_splitted_512K.wav',0
  nWAVESIZE  dd 0
  size512k equ 0x7ffff  ;512k to be save to trimmed wav file, change this in case wanna other file size


;  FileME   db 'z3-605_ME.bin',0
;  FileBIOS db 'z3-605_BIOS.bin',0


  hFile         dd 0
  BytesRead     dd 0
  BytesWritten  dd 0
  nSize         dd 0

  lpMemory      dd 0

  lpBytesRead   dd ?

;  lpBuffer rb 0x800000
  Buffer.size equ ($ - lpBuffer) ; Calculates the size at compile time
  NULL equ 0

  MessageBoxCaption db 'WAV file splitter, extract first 512KB, xiaolaba, 2026-FEB-28',0
  MsgOK db 'Done',0
  MsgNG db 'GlobalAlloc Failed',0

  buffer          rb 128          ; enough space for the string
  fmt_size_bytes  db 'WAV file size: %d bytes',0
  Caption_FileSize db 'WAV File Information',0

  fmt_size_dec_hex db 'WAV File size:',13,10
                   db '%d bytes',13,10
                   db '0x%08X (hex)',0



; code
main:

  ;read
  ; Read-only; other apps can read too; file must exist
  invoke  CreateFile, FileIn, GENERIC_READ, 0, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0 ; Open the file (to get its handle)
  ; TODO: TestApiError
  mov [hFile], eax ; Save the file's handle to hFile
  invoke  GetFileSize, [hFile], 0 ; Determine the file size
  ; TODO: TestApiError
  mov [nSize], eax ; Save the file size given by EAX

  ;;; Convert number to string for MessageBox
  ;invoke wsprintf, addr buffer, addr fmt_size_bytes, [nSize]
  ;;; buffer now contains something like "File size: 8388607 bytes"
  ;invoke MessageBox, NULL, addr buffer, addr Caption_FileSize, MB_OK or MB_ICONINFORMATION
  ;invoke MessageBox, NULL, addr buffer, addr FileIn, MB_OK or MB_ICONINFORMATION

  ;;; Convert number tostring for MessageBox
  invoke wsprintf, addr buffer, addr fmt_size_dec_hex, [nSize], [nSize]
  ;;; Show size in decimal + hex¢
  invoke MessageBox, NULL, addr buffer, addr FileIn, MB_OK or MB_ICONINFORMATION


  ;request buffer to hold file content
  ;invoke GlobalAlloc, GMEM_FIXED | GMEM_ZEROINIT, InitAllocSize
  invoke GlobalAlloc, (GMEM_FIXED + GMEM_ZEROINIT), [nSize] ;GMEM_FIXED, will return a handle in eax
  mov [lpMemory],eax    ; save return value anyway
  cmp eax,0             ; if return =0, failed
  jnz read_file
    ; error, no buffer to hold file content, nothing done
    invoke MessageBox, NULL, addr MsgNG, addr MessageBoxCaption, MB_OK
    invoke CloseHandle, [hFile] ; Handle should be closed
    invoke  ExitProcess, 0

read_file:
  ;invoke  ReadFile, [hFile], lpBuffer, [nSize], lpBytesRead, 0 ; Now read the full file
  invoke  ReadFile, [hFile], [lpMemory], [nSize], lpBytesRead, 0 ; Now read the full file
  ; TODO: TestApiError
  invoke CloseHandle, [hFile] ; Handle should be closed after the file has been read



  ; write to other file = copy a file
  ; write only; if the file doesn't exist, create it
  invoke CreateFile, FileOut, GENERIC_WRITE, NULL, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
  mov [hFile],eax
  invoke WriteFile, [hFile], [lpMemory], [nSize], BytesRead, NULL
  invoke CloseHandle,[hFile] ; done

  ;write to splitted .wav
  mov eax,0x8000000
  mov [nWAVESIZE], eax
  invoke CreateFile, WAV, GENERIC_WRITE, NULL, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
  mov [hFile],eax
  ;invoke WriteFile, [hFile], [lpMemory], [nWAVESIZE], BytesRead, NULL
  ;;invoke WriteFile, [hFile], [lpMemory], 0xfffffff, BytesRead, NULL
  invoke WriteFile, [hFile], [lpMemory], size512k, BytesRead, NULL
  invoke CloseHandle,[hFile] ; done


  ;write to ME.bin
;  invoke CreateFile, FileME, GENERIC_WRITE, NULL, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
;  mov [hFile],eax
;  mov eax,[lpMemory]
;  add eax,0x1000
;  invoke WriteFile, [hFile], eax, 0x500000-0x1000, BytesRead, NULL
;  invoke CloseHandle,[hFile] ; done

  ;write to BIOS.bin
;  invoke CreateFile, FileBIOS, GENERIC_WRITE, NULL, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
;  mov [hFile],eax
;  mov eax,[lpMemory]
;  add eax,0x500000
;  invoke WriteFile, [hFile], eax, 0x300000, BytesRead, NULL
;  invoke CloseHandle,[hFile] ; done



  ;signal user, job done
  invoke MessageBox, NULL, addr MsgOK, addr MessageBoxCaption, MB_OK

  ;release used buffer
  invoke GlobalAlloc,[lpMemory]

finish:
  invoke  ExitProcess, 0
 
.end main
