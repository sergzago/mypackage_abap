*&---------------------------------------------------------------------*
*& Report Z_STVARV
*&---------------------------------------------------------------------*
*& Проверка параметра в тр. STVARV на примере 'Z_DAY_PRINT'
*&---------------------------------------------------------------------*
REPORT Z_STVARV.
"DATA: lv_variable type c length 1.
DATA: lv_variable type abap_boolean.

SELECT SINGLE low
from TVARVC
into @lv_variable
where type EQ 'P' and name EQ 'ZPRICEROUNDDOWN'.

IF lv_variable is INITIAL. "OR SY-SUBRC <> 0.
  WRITE: |Параметр отсутствует или параметр не установлен|.
ELSE.
  WRITE: 'Параметр ZPRICEROUNDDOWN установлен'.
ENDIF.
