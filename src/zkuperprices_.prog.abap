*&---------------------------------------------------------------------*
*& Report ZKUPERPRICES
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZKUPERPRICES_.

types: begin of ty_prices,
        knumh type knumh,
        kschl type kscha,
        werks type werks_d,
        matnr type matnr,
        vrkme type vrkme,
        datbi_p type kodatbi,
        datab_p type kodatab,
        kbetr_p type kbetr_kond,
        datbi_a type kodatbi,
        datab_a type kodatab,
        kbetr_a type kbetr_kond,
       end of ty_prices.
DATA: ls_dostavka type c length 15,
      ls_kuperwerks type zkuperwerks,
      lt_kuperwerks type table of zkuperwerks,
      lt_a071vk type table of ty_prices,
      ls_a071vk type ty_prices,
      percent TYPE p LENGTH 8 DECIMALS 2,
      ls_kuperprice type zkuperprice,
      lv_new_date type d,
      lv_day_del type c length 3,
      lv_date_shift type c length 3,
      lv_current_date type d,
      lv_count type i,
      zprice_in type zzprice,
      zprice_out type zzprice,
      ls_mara type mara.

ls_dostavka = 'КУПЕР'.
  "Удаляем старые данные (по параметру z_del_kuper из TVARVC)
SELECT SINGLE low
    from TVARVC
    into @lv_day_del
    where type EQ 'P' and name EQ 'Z_DEL_KUPER'.

IF SY-SUBRC = 0.
    CALL FUNCTION 'CALCULATE_DATE'
      EXPORTING
        days      = lv_day_del
      IMPORTING
    result_date   = lv_new_date.
ENDIF.
delete from zkuperprice where erdat < @lv_new_date.
if sy-subrc = 0.
    commit work.
endif.

" Определяем сдвиг текущей даты (если выгрузка производится вечером, то надо настроить, чтобы данные за завтра выгружались)
select single low
  from TVARVC
  into @lv_date_shift
  where type EQ 'P' and name EQ 'Z_DATE_SHIFT'.

if sy-subrc = 0.
    CALL FUNCTION 'CALCULATE_DATE'
      EXPORTING
        days      = lv_date_shift
      IMPORTING
    result_date   = lv_current_date.
else.
    lv_current_date = sy-datum.
endif.

select * into table @lt_kuperwerks from zkuperwerks where zzdostav = @ls_dostavka.
if sy-subrc = 0.
  select single * into @ls_kuperprice from zkuperprice where erdat eq @lv_current_date. "@sy-datum. "Удаление данных за сегодня, если есть
  if sy-subrc = 0.
    delete from zkuperprice where erdat = lv_current_date. "sy-datum.
    commit work.
  endif.
  clear ls_kuperprice.

  loop at lt_kuperwerks into ls_kuperwerks.
    percent = 1 + ls_kuperwerks-zzpercent / 100.
    lv_count = 0.
    select
           a~knumh,
           a~kschl,
           a~werks,
           a~matnr,
           a~vrkme,
           a~datbi,
           a~datab,
           kp~kbetr,
           a1~datbi,
           a1~datab,
           kp1~kbetr
      into table @lt_a071vk
      from a071 as a
      join konp as kp on kp~knumh = a~knumh and kp~kschl = a~kschl
      left join a071 as a1 on a1~kschl = 'VKA0' and a1~werks = a~werks
                        and a1~vkorg = a~vkorg and a1~vtweg = a~vtweg
"                        and a1~matnr = a~matnr and a1~datab LE @sy-datum AND a1~datbi GE @sy-datum
                        and a1~matnr = a~matnr and a1~datab LE @lv_current_date AND a1~datbi GE @lv_current_date
      left join konp as kp1 on kp1~knumh = a1~knumh and kp1~kschl = a1~kschl
    where a~kappl = 'V'
        AND a~kschl = 'VKP0'
        AND a~vkorg = 'RU01'
        AND a~vtweg = '01'
        AND a~werks = @ls_kuperwerks-werks
        AND a~datab LE @sy-datum
        AND a~datbi GE @sy-datum.
      if sy-subrc = 0.
        loop at lt_a071vk into ls_a071vk.
          select single * from mara into @ls_mara where matnr = @ls_a071vk-matnr.
          if sy-subrc = 0.
             ls_kuperprice-vkorg = 'RU01'.
             ls_kuperprice-vtweg = '01'.
             ls_kuperprice-werks = ls_a071vk-werks.
             ls_kuperprice-matnr = ls_a071vk-matnr.
             ls_kuperprice-vrkme = ls_a071vk-vrkme.
             ls_kuperprice-erdat = lv_current_date. "sy-datum.
             ls_kuperprice-zzdepsale = ls_kuperwerks-zzdepsale.
*          ls_kuperprice-zprice_r = ls_a071vk-kbetr_p * percent.
*          ls_kuperprice-zprice_a = ls_a071vk-kbetr_a * percent.
             if ls_kuperwerks-zzweight NE 'X' and ls_mara-meins EQ 'KG'.
               ls_kuperprice-zprice_r = ls_a071vk-kbetr_p.
               ls_kuperprice-zprice_a = ls_a071vk-kbetr_a.
             else.
               clear zprice_out.
               zprice_in = ls_a071vk-kbetr_p * percent.
               perform zintervall using ls_a071vk-matnr ls_mara-matkl zprice_in
                            changing zprice_out.
               if zprice_out is initial.
                 zprice_out = zprice_in.
               endif.
               ls_kuperprice-zprice_r = zprice_out.
               clear zprice_out.
               zprice_in = ls_a071vk-kbetr_a * percent.
               perform zintervall using ls_a071vk-matnr ls_mara-matkl zprice_in
                            changing zprice_out.
               if zprice_out is initial.
                 zprice_out = zprice_in.
               endif.
               ls_kuperprice-zprice_a = zprice_out.
             endif.
             if ls_a071vk-kbetr_a = 0.
               ls_kuperprice-datab = ls_a071vk-datab_p.
               ls_kuperprice-datbi = ls_a071vk-datbi_p.
             else.
               ls_kuperprice-datab = ls_a071vk-datab_a.
               ls_kuperprice-datbi = ls_a071vk-datbi_a.
             endif.
             insert into zkuperprice values ls_kuperprice.
             if sy-subrc = 0.
               lv_count = lv_count + 1.
             endif.
           endif.
"          modify lt_a071vk from ls_a071vk index sy-tabix.
         endloop.
      endif.
     Write: / |Выгружено | && lv_count && | записей по заводу | && ls_kuperwerks-werks.
  endloop.
endif.

FORM ZINTERVALL USING matnr_in TYPE matnr
                      matkl_in TYPE matkl
                      zprice_in TYPE ZZPRICE
                CHANGING zprice_out TYPE ZZPRICE.
*"----------------------------------------------------------------------
*"*"Локальный интерфейс:
*"  IMPORTING
*"     REFERENCE(MATNR) TYPE  MATNR
*"     REFERENCE(PRICE_IN) TYPE  ZZPRICE
*"  EXPORTING
*"     REFERENCE(ZPRICE_OUT) TYPE  ZZPRICE
*"----------------------------------------------------------------------

  DATA:
        PI_PRSLA TYPE TWPG-PRSLA,
        PI_PRSDI TYPE TWPG-PRSDI,
        PI_RUNRG TYPE TWPK-RUNRG,
        PI_PRICE TYPE P DECIMALS 4,
        PE_PRICE TYPE TWPG-PRSFI,
        PI_PRSFI TYPE TWPG-PRSFI.

  DATA: DIFF_TOTAL TYPE P DECIMALS 4,       "Differenz zweier Preise
*       DIFF_TOTAL LIKE TWPG-PRSDI,      "Differenz zweier Preise
*       DIFF_LOW   LIKE TWPG-PRSDI,      "Differenz zweier Preise
*       DIFF_HIGH  LIKE TWPG-PRSDI,      "Differenz zweier Preise
        NUMBER_OF_STEPS TYPE I,          "Anzahl der Schritte
        PRICE_LOW  TYPE TWPG-PRSFI,      "Unterer Eckpreis
        PRICE_HIGH TYPE TWPG-PRSFI,      "Oberer Eckpreis
        REST       TYPE P DECIMALS 4,       "Rest bei ganzzahliger Division
*       REST       LIKE TWPG-PRSDI.      "Rest bei ganzzahliger Division
        PROZ       type TWPK-RUNRG,      "vgl. Rundungsregel
        SCHRANKE   TYPE P DECIMALS 4.       "für Rundung im Eckpreisbereich

  DATA: ls_twego type twego,
        ls_twpk type twpk,
        ls_twpg type twpg.

  select single * from twego into @ls_twego   " Выбираем вид округления
    where VKORG = 'RU01'
      and VTWEG = '01'
      and MATKL = @matkl_in
      and WAERK = 'RUB'
      and EPTYP = '01'.
  if sy-subrc = 0.
    select single * from twpk into @ls_twpk where eprgr = @ls_twego-eprgr. " Выбираем правило округления (twpk-runrg)
    if sy-subrc = 0.
      PI_RUNRG = ls_twpk-RUNRG.
      select single * from twpg into @ls_twpg
        where eprgr EQ @ls_twpk-eprgr
          and PRSFI LE @zprice_in
          and PRSLA GE @zprice_in.
      if sy-subrc = 0.      " Строка с правилом округления
          PI_PRSLA = ls_twpg-PRSLA.
          PI_PRSDI = ls_twpg-PRSDI.
          PI_PRICE = zprice_in.
          PI_PRSFI = ls_twpg-PRSFI.
* PI_PRICE trifft einen Eckpreis auf der Intervallgrenze --------------*
          IF PI_PRICE EQ PI_PRSFI OR PI_PRICE EQ PI_PRSLA.
            PE_PRICE = PI_PRICE.
            EXIT.
          ENDIF.

* Berechne den Rest der ganzzahligen Division -------------------------*
          DIFF_TOTAL = PI_PRICE - PI_PRSFI.
          REST = DIFF_TOTAL MOD PI_PRSDI.

* PI_PRICE trifft einen Eckpreis des Eckpreisbereiches ----------------*
          IF ( REST EQ 0 ) AND ( PROZ NE 100 ) .
            PE_PRICE = PI_PRICE.
            EXIT.
          ENDIF.

* PI_PRICE trifft keinen Eckpreis des Eckpreisbereiches ---------------*
          NUMBER_OF_STEPS = DIFF_TOTAL DIV PI_PRSDI.
          PRICE_LOW = PI_PRSFI + NUMBER_OF_STEPS * PI_PRSDI.
          PRICE_HIGH = PRICE_LOW + PI_PRSDI.
          PROZ = PI_RUNRG.
*  diff_low = rest.
          SCHRANKE = ( ( 100 - PROZ ) * PI_PRSDI ) / 100.
* diff_high = pi_prsdi - diff_low.
*  if diff_low ge diff_high.
*  if diff_low ge schranke.
          IF REST GE SCHRANKE.
            PE_PRICE = PRICE_HIGH.
          ELSE.
            PE_PRICE = PRICE_LOW.
          ENDIF.
          zprice_out = PE_PRICE.
      endif.
    endif.
  endif.

ENDFORM.
