*&---------------------------------------------------------------------*
*& Report ZDISLEVEL
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZDISLEVEL.




data: lv_level type KLASSE_D,
      lv_dis type c length 4,
      lv_cnt type i.

SELECT single matkl
  into @lv_level
  from mara
  where matnr = '000000000043002153'.
write: lv_level.

lv_cnt = 0.
while lv_level NE 'SPAR_URAL'.
  clear lv_dis.
  select single zdis into @lv_dis from zdisclass where zclass eq @lv_level.
  Write: / | { lv_level } - { lv_dis } |.
  if sy-subrc = 0.
    case lv_dis.
      when 'ИСКЛ'.
        exit.
      when 'ЗАПР'.
        write: | - Отгрузка запрещена|.
    endcase.
  else.
      lv_dis = |Нет|.
  endif.
  SELECT single k2~class  into @lv_level FROM klah as k1
    JOIN kssk as kk1 ON kk1~objek EQ k1~clint AND kk1~klart eq k1~klart
    JOIN klah as k2 ON k2~clint eq kk1~clint AND k2~klart eq kk1~klart
    WHERE k1~class = @lv_level.
  if sy-subrc <> 0.
    exit.
  endif.
  lv_cnt = lv_cnt + 1.
  if lv_cnt > 5.
    exit.
  endif.
ENDWHILE.
