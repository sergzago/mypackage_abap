*----------------------------------------------------------------------*
***INCLUDE ZEANDEL_CLASS.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Class lcl_app
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
CLASS lcl_app DEFINITION FINAL.
  PUBLIC SECTION.
    TYPES:
      tr_matnr TYPE RANGE OF matnr.
    METHODS:
      run
        IMPORTING
          ir_matnr TYPE tr_matnr,
      on_user_command FOR EVENT added_function OF cl_salv_events
        IMPORTING e_salv_function.

  PRIVATE SECTION.
    types: begin of ty_eanmatnr,
            matnr type matnr,
            maktx type maktx,
            meinh type meinh,
            ean11 type ean11,
            hpean type hpean,
            zzsetcode type zdt_setcode,
           end of ty_eanmatnr.

    DATA:
      mr_matnr  type tr_matnr,
      ls_matnr type ty_eanmatnr,
      lt_matnr type table of ty_eanmatnr,
      lo_alv TYPE REF TO cl_salv_table,
      lo_columns TYPE REF TO cl_salv_columns_table,
      lo_column TYPE REF TO cl_salv_column_table,
      lo_functions TYPE REF TO cl_salv_functions_list,
      lo_sorts type ref to cl_salv_sorts,
      lo_sort type ref to cl_salv_sort,
      mo_container    TYPE REF TO cl_gui_docking_container.


    METHODS:
      _get_main_data,
      _send_data,
      _init_alv,
      _setup_alv
        importing
          io_alv TYPE REF TO cl_salv_table,
      _refresh_alv.
ENDCLASS.
*&---------------------------------------------------------------------*
*& Class (Implementation) lcl_app
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
CLASS lcl_app IMPLEMENTATION.
  METHOD run.
    _get_main_data( ).
    _init_alv( ).
    CALL SCREEN 0100.
  ENDMETHOD.
  METHOD _get_main_data.
    select mean~matnr,
     makt~maktx,
     mean~meinh,
     mean~ean11,
     mean~hpean,
     mara~zzsetcode
    into table @lt_matnr
    from mean
      join mara on mara~matnr eq mean~matnr
      join makt on makt~matnr eq mara~matnr and spras eq 'R'
    where mean~matnr in @s_matnr
    order by mean~matnr,mean~meinh,mean~hpean DESCENDING,mean~ean11.
  ENDMETHOD.
  METHOD _init_alv.

    mo_container = NEW #(
      repid = sy-repid
      dynnr = '0100'
      extension = 10000
    ).
    TRY.
      cl_salv_table=>factory(
        EXPORTING
          r_container = mo_container
        IMPORTING
          r_salv_table = lo_alv
        CHANGING
          t_table      = lt_matnr ).
    CATCH cx_salv_msg INTO DATA(lx_salv_msg).
      " Обработка ошибок
      MESSAGE lx_salv_msg->get_text( ) TYPE 'E'.
    ENDTRY.
    _setup_alv( EXPORTING io_alv = lo_alv  ).
    lo_alv->display( ).
  ENDMETHOD.
  METHOD _setup_alv.
    data: lv_icon type string.

    data: lo_functions type ref to cl_salv_functions_list.
*   Включаем все функции alv-представления
       lo_functions = io_alv->get_functions( ).
       lo_functions->set_all( ).
*   Сортируем по коду материала
       lo_sorts = io_alv->get_sorts( ).
       lo_sort = lo_sorts->add_sort(
          columnname = 'MATNR'
          position = 1
          sequence = if_salv_c_sort=>sort_up ).
       lo_sort = lo_sorts->add_sort(
          columnname = 'MAKTX'
          position = 2
          sequence = if_salv_c_sort=>sort_up ).
       try.
         clear lv_icon.
         call method lo_functions->add_function
           exporting
             name = 'DELSEND'
             icon = lv_icon
             text = |{ 'Удалить и отправить'(t03)  }|
             tooltip = |{ 'Удалить и отправить'(t03)  }|
             position = 2.
          CATCH cx_salv_msg cx_salv_existing cx_salv_wrong_call ##NO_HANDLER.
       endtry.
       data(lo_events) = io_alv->get_event( ).
       set handler on_user_command for lo_events.
  ENDMETHOD.
  METHOD _refresh_alv.
    data: ls_stable type lvc_s_stbl.

    ls_stable-row = abap_true.
    ls_stable-col = abap_true.

    _get_main_data( ).
    call method lo_alv->refresh
      exporting
        s_stable = ls_stable.
  ENDMETHOD.
  METHOD on_user_command.
    CASE e_salv_function.
      WHEN 'DELSEND'.
        _send_data( ).
    ENDCASE.
  ENDMETHOD.
  METHOD _send_data.
    data: lv_answer type c length 1,
          lo_selections type ref to cl_salv_selections,
          lt_rows type salv_t_row,
          ls_row type i,
          lv_zzsetcode type zdt_setcode,
          lt_del_barcode type table of ty_eanmatnr,   "Удаленные ш/к
          ls_del_barcode type ty_eanmatnr,            "Строка удаляемых ш/к
          lv_barcode_hp type ean11,
          lv_barcode_ei type meinh,
          lv_barcode_numtp type numtp,
          ls_mean type mean,
          ls_mean2 type mean,
          lt_mean type table of mean,
          ls_mara type mara,
          ls_marm type marm.

    data: lo_proxy type ref to zco_si_del_barcode_async_out,
          ls_out type zmt_del_bar_code.

    call function 'POPUP_TO_CONFIRM'
      exporting
         titlebar         = 'Подтверждение'
         text_question    = 'Вы уверены, что хотите удалить ш/к?'
         display_cancel_button = ''
      importing
         answer           = lv_answer.
    case lv_answer.
        when '1'.
          lo_selections = lo_alv->get_selections( ).
          lt_rows = lo_selections->get_selected_rows( ).
          clear ls_row.
          clear ls_out.
          clear lt_del_barcode.
          loop at lt_rows into ls_row.
            read table lt_matnr into ls_matnr index ls_row.
            lv_zzsetcode = ls_matnr-zzsetcode.
            shift lv_zzsetcode left deleting leading space.
            shift lv_zzsetcode left deleting leading '0'.
            insert value #( code = ls_matnr-ean11
                            deleted = 'X'
                            marking_of_the_good = lv_zzsetcode )
                       into table ls_out-mt_del_bar_code-bar_code.
            append ls_matnr to lt_del_barcode.
          endloop.
* Отправку пока закомментируем
*          if lines( ls_out-mt_del_bar_code-bar_code ) > 0.
*            try.
*              create object lo_proxy.
*              lo_proxy->SI_DEL_BAR_CODE_ASYNC_OUT( ls_out ).
*            catch cx_root into data(lo_err).
*              message 'Отправка неудачна'(m03) type 'I'.
*              return.
*            endtry.
*            commit work and wait.
*            message |{ 'Отправлено записей'(m04) } { lines( ls_out-mt_del_bar_code-bar_code ) }| TYPE 'I'.
*          endif.
* После удачной отправки на кассы удаляем ш/к в САП
          loop at lt_del_barcode into ls_del_barcode.
            clear ls_mean.
            clear ls_mean2.
            clear ls_mara.
            clear ls_marm.
            select single * from mean into ls_mean
              where matnr = ls_del_barcode-matnr
                and meinh = ls_del_barcode-meinh
                and ean11 = ls_del_barcode-ean11.
            if sy-subrc = 0.
              delete from mean where matnr = ls_mean-matnr "ls_del_barcode-matnr
                                 and meinh = ls_mean-meinh "ls_del_barcode-meinh
                                 and ean11 = ls_mean-ean11. "ls_del_barcode-ean11.
              if sy-subrc = 0.
                commit work.
                " Необходимо проверить, не удален ли основной ш/к по основной ЕИ
                lv_barcode_ei = ls_mean-meinh. "ls_del_barcode-meinh.
                 if ls_mean-hpean = 'X'.  " Удален основной ш/к
                    lv_barcode_hp = ''.
                    lv_barcode_numtp = ''.
                    select single * from mean into ls_mean2
                      where matnr = ls_mean-matnr "ls_del_barcode-matnr
                            and meinh = ls_mean-meinh. "ls_del_barcode-meinh.
                    if sy-subrc = 0.  "Есть штрихкод для этого материала
                        lv_barcode_hp = ls_mean2-ean11.
                        lv_barcode_numtp = ls_mean2-eantp.
                        ls_mean2-hpean = 'X'.
                        modify mean from ls_mean2.
                        if sy-subrc = 0.
                          commit work.
                        endif.
                    endif.
                    select single * from mara into ls_mara
                      where matnr eq ls_mean-matnr and meins eq ls_mean-meinh. "ls_del_barcode-matnr.
                    if sy-subrc = 0. " Заменяем ш/к на основной в mara
                        ls_mara-ean11 = lv_barcode_hp.
                        ls_mara-numtp = lv_barcode_numtp.
                        modify mara from ls_mara.
                        if sy-subrc = 0.
                           commit work.
                        endif.
                       select single * from marm into ls_marm
                         where matnr eq ls_mean-matnr "ls_del_barcode-matnr
                           and meinh eq ls_mean-meinh. "ls_del_barcode-meinh.
                       if sy-subrc = 0.
                          ls_marm-ean11 = lv_barcode_hp.
                          ls_marm-numtp = lv_barcode_numtp.
                          update marm from ls_marm.
                          if sy-subrc = 0.
                            commit work.
                          endif.
                       endif.
                    endif.
                endif.
              else.
                 rollback work.
              endif.
            endif.
          endloop.
          _refresh_alv( ).
        when '2'.
          write: / 'Мне страшно!!'.
    endcase.
  ENDMETHOD.
ENDCLASS.
