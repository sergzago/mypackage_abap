*&---------------------------------------------------------------------*
*& Report ZSCREENTEST
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZSCREENTEST.

DATA: gv_loaded TYPE abap_bool.

SELECTION-SCREEN BEGIN OF SCREEN 100.
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME.
  PARAMETERS p_matnr TYPE matnr.
  PARAMETERS p_meins TYPE meins MODIF ID dis.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME.
  SELECTION-SCREEN PUSHBUTTON /10(10) btn_load
    USER-COMMAND load.
  SELECTION-SCREEN PUSHBUTTON /10(10) btn_clr
    USER-COMMAND clear.
SELECTION-SCREEN END OF BLOCK b2.
SELECTION-SCREEN END OF SCREEN 100.

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    IF screen-group1 = 'DIS'.
      screen-input = 0.  " Только для чтения
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

  IF gv_loaded = abap_true.
    btn_load = 'Обновить данные'.  " Меняем текст после загрузки
  ENDIF.

AT SELECTION-SCREEN.
  CASE sy-ucomm.
    WHEN 'LOAD'.
      PERFORM load_data.
    WHEN 'CLEAR'.
      PERFORM clear_data.
  ENDCASE.

FORM load_data.
  CHECK p_matnr IS NOT INITIAL.
  SELECT SINGLE meins FROM mara INTO p_meins
    WHERE matnr = p_matnr.
  IF sy-subrc = 0.
    gv_loaded = abap_true.
    MESSAGE 'Данные загружены!' TYPE 'S'.
  ELSE.
    MESSAGE 'Материал не найден!' TYPE 'E'.
  ENDIF.
ENDFORM.

FORM clear_data.
  CLEAR: p_matnr, p_meins, gv_loaded.
  MESSAGE 'Поля очищены!' TYPE 'S'.
ENDFORM.

START-OF-SELECTION.
  btn_load = 'Загрузка'.
  btn_clr = 'Очистка'.
  CALL SELECTION-SCREEN 100.
