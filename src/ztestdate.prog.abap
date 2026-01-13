*&---------------------------------------------------------------------*
*& Report ZTESTDATE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZTESTDATE.

DATA: DAY1 TYPE SCAL-INDICATOR.
DATA: begin of ls_print_date,
   DATE_OPER TYPE ZDT_DATE_OPER,
   DATE_QNT TYPE ZDT_DATE_QNT,
   PRINT_TIME TYPE ZDT_PRINT_TIME,
   end of ls_print_date.

clear ls_print_date.

SELECT SINGLE low
from TVARVC
into @DATA(lv_variable)
where type EQ 'P' and name EQ 'Z_DAY_PRINT'.


IF lv_variable = '' OR SY-SUBRC <> 0.
   SELECT DATE_OPER,
        DATE_QNT,
        PRINT_TIME
     FROM ztlbl_print_date
     INTO @ls_print_date
     UP TO 1 ROWS.
   ENDSELECT.
ELSE.
  CALL FUNCTION 'DATE_COMPUTE_DAY'
    EXPORTING
       DATE = SY-DATUM
    IMPORTING
       DAY = DAY1.

  SELECT DATE_OPER,
       DATE_QNT,
       PRINT_TIME
    FROM ztb_print_date
    WHERE DAY_WEEK EQ @DAY1
    INTO @ls_print_date
    UP TO 1 ROWS.
  ENDSELECT.
ENDIF.

WRITE: DAY1,ls_print_date-date_oper,ls_print_date-date_qnt,ls_print_date-PRINT_TIME,lv_variable.

" Загоскин С. 2025-01-13
