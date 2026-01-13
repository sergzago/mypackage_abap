*&---------------------------------------------------------------------*
*& Report ZSEQEMPTY
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZSEQEMPTY.
DATA: lt_numbers TYPE TABLE OF i,
      lt_missing TYPE TABLE OF i,
      lv_index   TYPE i.

" Заполняем таблицу числами от 1 до 100, пропуская одно значение
DO 100 TIMES.
  IF sy-index <> 42 AND sy-index <> 95. " Пропускаем число 42 для примера
    APPEND sy-index TO lt_numbers.
  ELSE.
    APPEND 0 TO lt_numbers.
  ENDIF.
ENDDO.

" Сортируем таблицу для удобства поиска
"SORT lt_numbers ASCENDING.

" Поиск пропущенного числа
LOOP AT lt_numbers INTO DATA(lv_number).
  lv_index = sy-tabix. " Текущий индекс

  " Если текущее число не равно индексу, значит, найдено пропущенное число
  IF lv_number = 0. "lv_number <> lv_index.
    APPEND lv_index TO lt_missing.
    "EXIT. " Выход из цикла, так как пропущенное число найдено
  ENDIF.
ENDLOOP.

" Вывод результата
LOOP AT lt_missing into DATA(lv_missing).
  WRITE: / 'Пропущенное число:', lv_missing.
ENDLOOP.
