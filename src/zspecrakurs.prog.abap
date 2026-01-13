*&---------------------------------------------------------------------*
*& Report ZSPECRAKURS
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZSPECRAKURS.
    TYPES:
      BEGIN OF ts_unique_werks,
        werks   TYPE werks_d,
        kalaid  TYPE ck_kalaid,
        r_werks TYPE RANGE OF werks_d,
        t_matnr TYPE SORTED TABLE OF matnr WITH UNIQUE KEY table_line,
      END OF ts_unique_werks.

    TYPES:
      tt_unique_werks TYPE SORTED TABLE OF ts_unique_werks WITH UNIQUE KEY werks.

    DATA:
      lv_kalaid TYPE n LENGTH 8,
      r_matnr type range of mara-matnr,
      werks_r type range of werks_d,
      mt_mat_type TYPE STANDARD TABLE OF ztmat_type_ck40n-mtart,
      MT_UNIQUE_WERKS type TT_UNIQUE_WERKS.

 r_matnr = VALUE #( ( SIGN = 'I' OPTION = 'BT' LOW = '43000000' HIGH = '43009999') ).
 werks_r = VALUE #( ( SIGN = 'I' OPTION = 'EQ' LOW = '1004') ).


      select distinct
        mr~matnr,
        mr~mtart,
        mk~werks,
        mk~adatu,
        mk~bdatu,
        st~stlnr,
        st~stlal,
        mb~pstat,
        mc~pstat as pstat_mc
        into table @data(lt_mara1)
        from mkal as mk
        inner join mara as mr on mr~matnr eq mk~matnr
        inner join mast as mt on mt~matnr eq mk~matnr and mt~werks eq mk~werks and mt~stlal eq mk~stlal
        inner join stko as st on st~stlnr eq mt~stlnr and st~stlal eq mt~stlal and st~stlst eq '01'
        inner join mbew as mb on mb~matnr eq mk~matnr and mb~bwkey eq mk~werks and mb~pstat eq 'B'
        inner join marc as mc on mc~matnr eq mk~matnr and mc~werks eq mk~werks
      "where mk~werks in @werks_r

      .
    IF sy-subrc NE 0.
      "RAISE EXCEPTION TYPE zcx_mass_cost_estimate
      "  EXPORTING
      "    textid = zcx_mass_cost_estimate=>matnr_not_found. " Материалы не найдены!
      WRITE: 'Материалы снова не найдены!'.
    ENDIF.
