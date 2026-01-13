*&---------------------------------------------------------------------*
*& Report ZALVTABLE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZALVTABLE.

TABLES: mara.

DATA: lt_mara TYPE TABLE OF mara,
      ls_mara TYPE mara.

DATA: lo_alv TYPE REF TO cl_salv_table,
      lo_columns TYPE REF TO cl_salv_columns_table,
      lo_column TYPE REF TO cl_salv_column_table.

START-OF-SELECTION.

  " Выбираем данные из таблицы MARA
  SELECT * FROM mara INTO TABLE lt_mara UP TO 100 ROWS.

  " Создаем ALV-таблицу
  TRY.
      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = lo_alv
        CHANGING
          t_table      = lt_mara ).

      " Получаем доступ к колонкам
      lo_columns = lo_alv->get_columns( ).

      " Настраиваем колонки (опционально)
      lo_column ?= lo_columns->get_column( 'MATNR' ).
      lo_column->set_short_text( 'Material' ).
      lo_column->set_medium_text( 'Material Number' ).
      lo_column->set_long_text( 'Material Number' ).

      lo_column ?= lo_columns->get_column( 'MTART' ).
      lo_column->set_short_text( 'Type' ).
      lo_column->set_medium_text( 'Material Type' ).
      lo_column->set_long_text( 'Material Type' ).

      " Отображаем ALV-таблицу
      lo_alv->display( ).

    CATCH cx_salv_msg INTO DATA(lx_salv_msg).
      " Обработка ошибок
      MESSAGE lx_salv_msg->get_text( ) TYPE 'E'.
  ENDTRY.
