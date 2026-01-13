*&---------------------------------------------------------------------*
*& Report ZCLEARADEXT
*&---------------------------------------------------------------------*
*& Очистка ш/к уволенных сотрудников по списку из файла
*&
*&---------------------------------------------------------------------*
REPORT ZCLEARADEXT_.


types: begin of ty_partners,
    partner type BU_PARTNER,
    name1 type BU_MCNAME1,
  end of ty_partners.

DATA: lt_partners TYPE TABLE OF ty_partners,
      ls_partner  TYPE ty_partners,
      ls_adext type BU_ADEXT,
      lt_file_table TYPE TABLE OF string,
      lv_file_line  TYPE string,
      lv_partner_code TYPE bu_partner,
      lv_filename TYPE rlgrap-filename,
      lv_answer type c length 1,
      lv_count type i value 0.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
PARAMETERS: p_file TYPE string. "rlgrap-filename.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
PARAMETERS: p_manual TYPE c AS CHECKBOX USER-COMMAND flag.
SELECT-OPTIONS: s_partn FOR lv_partner_code.
SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-003.
PARAMETERS: p_test TYPE c AS CHECKBOX USER-COMMAND test DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b3.

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    IF p_manual = 'X'.
      IF screen-group1 = 'FILE'.
        screen-active = 0.
      ELSEIF screen-group1 = 'MANUAL'.
        screen-active = 1.
      ENDIF.
    ELSE.
      IF screen-group1 = 'FILE'.
        screen-active = 1.
      ELSEIF screen-group1 = 'MANUAL'.
        screen-active = 0.
      ENDIF.
    ENDIF.
    MODIFY SCREEN.
  ENDLOOP.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  CALL FUNCTION 'WS_FILENAME_GET'
      EXPORTING
        mask      = '*.*'
        title     = 'Выберите файл'
      IMPORTING
        filename  = p_file
      EXCEPTIONS
        OTHERS    = 1.


START-OF-SELECTION.

  IF p_manual = 'X'.
    " Выбор деловых партнеров вручную
    if s_partn is not initial.
      SELECT partner, mc_name1
        INTO TABLE @lt_partners
        FROM but000
        WHERE partner IN @s_partn.
    endif.
  ELSE.
    " Загрузка файла и обработка
    CALL FUNCTION 'GUI_UPLOAD'
      EXPORTING
        filename = p_file
      TABLES
        data_tab = lt_file_table.

    IF lt_file_table IS NOT INITIAL.
      LOOP AT lt_file_table INTO lv_file_line.
        " Предполагаем, что файл содержит коды деловых партнеров
        lv_partner_code = lv_file_line.

        " Получение данных делового партнера
         select single partner,mc_name1
           into @ls_partner
          from but000
          where partner EQ @lv_partner_code.
          if sy-subrc = 0.
            insert ls_partner into table lt_partners.
          endif.
      ENDLOOP.
    ELSE.
      MESSAGE 'Файл пуст или не удалось загрузить' TYPE 'I'.
    ENDIF.
ENDIF.

data: ls_but020 type but020.

IF lt_partners IS NOT INITIAL.
  lv_count = lines( lt_partners ).
  data(lv_message) = |Будет обработано { lv_count } записей. Продолжить обработку?|.
" Вызов диалогового окна
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = 'Подтверждение'
      text_question         = lv_message
      text_button_1         = 'Продолжить'
*      text_button_2         = 'Отменить'
      default_button        = '1'
      display_cancel_button = 'X'
    IMPORTING
      answer                = lv_answer.

  if lv_answer = '1'.
   LOOP AT lt_partners INTO ls_partner.
    if ls_partner-partner GE '7000000000' AND ls_partner-partner LE '7999999999'.
      select single * into @ls_but020 from but020 where partner = @ls_partner.
      if sy-subrc = 0.
         WRITE: / 'Деловой партнер:', ls_partner-partner, 'Имя:', ls_partner-name1, 'ш/к ', ls_but020-adext.
         IF p_test <> 'X'.
           ls_but020-adext = ''.
           update but020 from @ls_but020.
           if sy-subrc = 0.
                WRITE: 'ш/к удален'.
                commit work.
           else.
                rollback work.
           endif.
        endif.
      ELSE.
          WRITE: / 'Деловой партнер:', ls_partner-partner, 'Имя:', ls_partner-name1, 'не найден'.
      endif.
    else.
          WRITE: / 'Деловой партнер:', ls_partner-partner, 'Имя:', ls_partner-name1, 'не корректен'.
    endif.
   ENDLOOP.
  endif.
ELSE.
   MESSAGE 'Деловые партнеры не найдены' TYPE 'I'.
ENDIF.
