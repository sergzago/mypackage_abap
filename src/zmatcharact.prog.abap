*&---------------------------------------------------------------------*
*& Report ZMATCHARACT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZMATCHARACT.

Data:
      lt_characteristics TYPE TABLE OF bapimatcha.

*DATA: lv_variable type abap_boolean.
*
*SELECT SINGLE low
*from TVARVC
*into @lv_variable
*where type EQ 'P' and name EQ 'ZCHARACTSQL'.

data lv_charactsql type flag.
    lv_charactsql = zcl_nov_tvarvc_helper=>get_p( 'ZCHARACTSQL' ).

if lv_charactsql is initial or lv_charactsql eq abap_false.
  write: / |Данные через BAPI|.
else.
  select cn~atnam as name_char,
      c~atbez as descr_char,
      ' ' as relevancy,
      a~atwrt as char_value,
      a~atwrt as descr_cval,
      a~atwrt as char_value_long,
      a~atwrt as descr_cval_long
    into table @lt_characteristics
    from inob as i
   inner join ausp as a on a~objek eq i~cuobj
   inner join cabn as cn on a~atinn eq cn~atinn
   inner join cabnt as c on cn~atinn eq c~atinn and c~spras eq 'R'
  where i~obtab eq 'MARAT' and i~klart eq '026' and i~objek eq '000000000041173922'.
 write: / |Выгрузка|.
endif.
