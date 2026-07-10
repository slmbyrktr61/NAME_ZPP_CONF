CLASS zcl_pp_conf DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION .

    CONSTANTS:
      mc_bomexplosionapplication  TYPE c LENGTH 4 VALUE 'PP01',
      mc_plant                    TYPE werks_d VALUE '0100',
      mc_requiredquantity         TYPE menge_d    VALUE '1',
      mc_explodebomlevelvalue     TYPE int4       VALUE 0,
      mc_bomexplosionismultilevel TYPE abap_bool  VALUE abap_false,
      mc_billofmaterialcategory   TYPE c LENGTH 1 VALUE 'M',
      mc_default_bom_usage        TYPE c LENGTH 1 VALUE '1',
      mc_bomitemcat_z             TYPE postp VALUE 'Z',
      mc_billofmaterialvariant    TYPE c LENGTH 2 VALUE '01',
      mc_mess_id                  TYPE symsgid VALUE 'ZPP_CONF',
      mc_dt_eat                   TYPE zpp_t_conf_dwntm-downtime_code VALUE '11',
      mc_dur_default              TYPE zpp_t_conf_dwntm-downtime_duration VALUE '30',
      mc_prodtype_1003            TYPE zi_product_vh-producttype VALUE '1003'.

    CONSTANTS: mc_ut_sarjli            TYPE zpp_t_conf_010-uretimturu VALUE 'SARJLI',
               mc_ut_ym_kurabiye_simit TYPE zpp_t_conf_010-uretimturu VALUE 'YM_KURABIYE_SIMIT',
               mc_ut_mamul_kurabiye    TYPE zpp_t_conf_010-uretimturu VALUE 'MAMUL_KURABIYE',
               mc_ut_ym_borek          TYPE zpp_t_conf_010-uretimturu VALUE 'YM_BOREK',
               mc_ut_mamul_borek       TYPE zpp_t_conf_010-uretimturu VALUE 'MAMUL_BOREK',
               mc_ut_mamul_ee_lahmacun TYPE zpp_t_conf_010-uretimturu VALUE 'MAMUL_EE_LAHMACUN',
               mc_ut_ym_ee_lahmacun    TYPE zpp_t_conf_010-uretimturu VALUE 'YM_EE_LAHMACUN'.

    TYPES:
      BEGIN OF ty_conf_log_i,
        status       TYPE bapiret2-type,
        message_text TYPE zpp_de_conf_mess,
      END OF ty_conf_log_i.

    TYPES tt_conf_log_i TYPE STANDARD TABLE OF ty_conf_log_i WITH EMPTY KEY.

    TYPES: BEGIN OF ty_conf_log_h,
             pid                TYPE abp_behv_pid,
             confuuid           TYPE zpp_i_conf_h-confuuid,
             shiftcode          TYPE zpp_i_conf_h-shiftcode,
             groupcode          TYPE zpp_i_conf_h-groupcode,
             material           TYPE zpp_i_conf_h-material,
             plant              TYPE zpp_i_conf_h-plant,
             productionquantity TYPE zpp_i_conf_h-productionquantity,
             baseunit           TYPE zpp_i_conf_h-baseunit,
             productionbatch    TYPE zpp_i_conf_h-productionbatch,
             productionversion  TYPE i_productionversion-productionversion,
             log_date           TYPE datum,
             log_time           TYPE uzeit,
             created_by         TYPE syuname,
             downtime           TYPE abap_boolean,
             item               TYPE  tt_conf_log_i,
           END OF ty_conf_log_h.

    TYPES:
      BEGIN OF ty_result,
        material                    TYPE matnr,
        plant                       TYPE werks_d,
        component                   TYPE matnr,
        component_text              TYPE maktx,
        quantity                    TYPE menge_d,
        unit                        TYPE meins,
        storage_location            TYPE lgort_d,
        bom_item_number             TYPE c LENGTH 8,
        bom_item_cat                TYPE postp,
        isbatchmanagementrequired   TYPE abap_bool,
        bomheaderquantityinbaseunit TYPE menge_d,
      END OF ty_result,
      tt_result TYPE STANDARD TABLE OF ty_result WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_prod_version,
        material              TYPE i_productionversion-material,
        plant                 TYPE i_productionversion-plant,
        productionversion     TYPE i_productionversion-productionversion,
        billofmaterialvariant TYPE i_productionversion-billofmaterialvariant,
      END OF ty_prod_version.

    TYPES:
      BEGIN OF ty_prod_type,
        material   TYPE zpp_t_conf_010-malzeme,
        uretimturu TYPE zpp_t_conf_010-uretimturu,
      END OF ty_prod_type.

    TYPES:
      BEGIN OF ty_charge_quantity,
        malzeme     TYPE zpp_t_conf_011-malzeme,
        sarjmiktari TYPE zpp_t_conf_011-sarjmiktari,
      END OF ty_charge_quantity.

    TYPES:
      BEGIN OF ty_local_datetime,
        datum TYPE datum,
        uzeit TYPE uzeit,
      END OF ty_local_datetime.

    TYPES:
      BEGIN OF ty_dt_material,
        malzeme     TYPE zpp_t_conf_015-malzeme,
      END OF ty_dt_material.


    CLASS-METHODS: explode_bom
      IMPORTING
        iv_material    TYPE matnr
        iv_quantity    TYPE menge_d DEFAULT 1
        iv_bom_usage   TYPE char1 DEFAULT '1'
      RETURNING
        VALUE(results) TYPE tt_result,
      save_conf_log IMPORTING is_conf_log TYPE ty_conf_log_h,
      get_prod_version IMPORTING iv_material            TYPE matnr
                                 iv_plant               TYPE werks_d DEFAULT mc_plant
                       RETURNING
                                 VALUE(rs_prod_version) TYPE ty_prod_version,
      get_prod_type IMPORTING iv_material         TYPE matnr
                    RETURNING VALUE(rs_prod_type) TYPE ty_prod_type,
      get_charge_quan IMPORTING iv_material               TYPE matnr
                      RETURNING VALUE(rs_charge_quantity) TYPE ty_charge_quantity,
      change_batch_prod_date,
      convert_material_quantity   IMPORTING
                                    iv_product    TYPE matnr
                                    iv_source_qty TYPE zpp_de_quan_l
                                    iv_source_uom TYPE msehi
                                    iv_target_uom TYPE msehi
                                  EXPORTING
                                    ev_target_qty TYPE menge_d,
      get_bom_item_cat
        IMPORTING
          iv_material          TYPE matnr
          iv_component         TYPE matnr
          iv_plant             TYPE werks_d DEFAULT mc_plant
        RETURNING
          VALUE(rv_bomitemcat) TYPE postp,
      set_downtime_eat IMPORTING is_conf_log TYPE ty_conf_log_h,
      get_local_datetime RETURNING VALUE(rs_datetime) TYPE ty_local_datetime,
      get_mat_downtime_eat IMPORTING iv_material    TYPE matnr
                           RETURNING VALUE(rs_data) TYPE ty_dt_material.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_pp_conf IMPLEMENTATION.


  METHOD get_local_datetime.
    DATA: timezone TYPE timezone.

    GET TIME STAMP FIELD DATA(lv_timestamp).

    TRY.
        timezone = cl_abap_context_info=>get_user_time_zone( ).
      CATCH cx_abap_context_info_error.
        timezone = 'TURKEY'.
    ENDTRY.


    CONVERT TIME STAMP lv_timestamp
            TIME ZONE timezone
            INTO DATE rs_datetime-datum
                 TIME rs_datetime-uzeit.

  ENDMETHOD.


  METHOD set_downtime_eat.

    DATA(ls_datetime) = zcl_pp_conf=>get_local_datetime( ).

    IF is_conf_log-shiftcode IS INITIAL
    OR is_conf_log-groupcode IS INITIAL
    OR is_conf_log-material  IS INITIAL.
      RETURN.
    ENDIF.

    SELECT SINGLE @abap_true
      FROM zpp_t_conf_dwntm
      WHERE shiftcode     = @is_conf_log-shiftcode
        AND groupcode     = @is_conf_log-groupcode
        AND material      = @is_conf_log-material
        AND downtime_date = @ls_datetime-datum
        AND downtime_code = @mc_dt_eat
      INTO @DATA(lv_exists).
    IF lv_exists = abap_true.
      RETURN.
    ENDIF.
    TRY.
        DATA(lv_uuid) = to_upper( cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ) ).
      CATCH cx_uuid_error INTO DATA(lr_uuid_err).
    ENDTRY.
    GET TIME STAMP FIELD DATA(lv_created_at).
    DATA(ls_dwntm) = VALUE zpp_t_conf_dwntm(
      downtime_uuid      = lv_uuid
      shiftcode          = is_conf_log-shiftcode
      groupcode          = is_conf_log-groupcode
      workcenter         = ''
      material           = is_conf_log-material
      downtime_date      = ls_datetime-datum
      downtime_time      = ls_datetime-uzeit
      shift              = |{ is_conf_log-shiftcode+1(1) }{ is_conf_log-groupcode }|
      downtime_code      = mc_dt_eat
      downtime_duration  = mc_dur_default
      created_by = cl_abap_context_info=>get_user_technical_name( )
      created_at = lv_created_at ).
    MODIFY zpp_t_conf_dwntm FROM @ls_dwntm.

  ENDMETHOD.

  METHOD explode_bom.

    DATA(lv_material) = CONV matnr( |{ iv_material ALPHA = IN WIDTH = 18 }| ).

    DATA(ls_prodver) = zcl_pp_conf=>get_prod_version(
      iv_material = lv_material
      iv_plant    = mc_plant
    ).

    IF ls_prodver-billofmaterialvariant IS INITIAL.
      RETURN.
    ENDIF.

    SELECT SINGLE billofmaterial,
                  billofmaterialvariant,
                  material,
                  plant,
                  billofmaterialvariantusage
      FROM i_materialbomlink
      WHERE billofmaterialvariant = @ls_prodver-billofmaterialvariant
        AND material              = @lv_material
        AND plant                 = @mc_plant
      INTO @DATA(ls_matbomlink).

    IF sy-subrc <> 0 OR ls_matbomlink-billofmaterial IS INITIAL.
      RETURN.
    ENDIF.

    READ ENTITIES OF i_billofmaterialtp_2 PRIVILEGED
      ENTITY billofmaterial
        EXECUTE explodebom
        FROM VALUE #(
          (
            billofmaterial                  = ls_matbomlink-billofmaterial
            plant                           = mc_plant
            material                        = lv_material
            billofmaterialcategory          = mc_billofmaterialcategory
            billofmaterialvariant           = ls_prodver-billofmaterialvariant
            %param-bomexplosionapplication  = mc_bomexplosionapplication
            %param-requiredquantity         = iv_quantity
            %param-explodebomlevelvalue     = mc_explodebomlevelvalue
            %param-bomexplosionismultilevel = mc_bomexplosionismultilevel
          )
        )
      RESULT DATA(lt_exploded_bom)
      FAILED DATA(ls_failed)
      REPORTED DATA(ls_reported).

    IF ls_failed IS NOT INITIAL.
      RETURN.
    ENDIF.

    results = VALUE #(
      FOR ls_item IN lt_exploded_bom
      (
        material                  = lv_material
        plant                     = mc_plant
        component                 = CONV matnr( |{ ls_item-%param-billofmaterialcomponent ALPHA = IN WIDTH = 18 }| )
        component_text            = ls_item-%param-componentdescription
        unit                      = ls_item-%param-billofmaterialitemunit
        quantity                  = ls_item-%param-componentquantityincompuom "componentquantityinbaseuom
        storage_location          = ls_item-%param-prodorderissuelocation
        bom_item_number           = ls_item-%param-billofmaterialitemnumber
        bom_item_cat              = ls_item-%param-billofmaterialitemcategory
        bomheaderquantityinbaseunit = ls_item-%param-bomheaderquantityinbaseunit
        isbatchmanagementrequired = abap_false
      )
    ).

    IF results IS INITIAL.
      RETURN.
    ENDIF.

    " BOM bileşenlerinin batch management bilgisini oku
    SELECT p~product,
           p~isbatchmanagementrequired
      FROM i_product AS p
      INNER JOIN @results AS r
        ON r~component = p~product
      INTO TABLE @DATA(lt_product).

    SORT lt_product BY product.

    LOOP AT results ASSIGNING FIELD-SYMBOL(<ls_result>).

      READ TABLE lt_product ASSIGNING FIELD-SYMBOL(<ls_product>)
        WITH KEY product = <ls_result>-component
        BINARY SEARCH.

      IF sy-subrc = 0.
        <ls_result>-isbatchmanagementrequired = <ls_product>-isbatchmanagementrequired.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD save_conf_log.


    DATA: lt_conf_log TYPE STANDARD TABLE OF zpp_t_conf_log WITH EMPTY KEY,
          ls_conf_log TYPE zpp_t_conf_log,
          lv_mess     TYPE string.

    IF is_conf_log IS INITIAL.
      RETURN.
    ENDIF.

    ls_conf_log = CORRESPONDING #( is_conf_log ).
    DATA(ls_datetime) = zcl_pp_conf=>get_local_datetime( ).
    ls_conf_log-log_date   = ls_datetime-datum.
    ls_conf_log-log_time   = ls_datetime-uzeit.
    ls_conf_log-created_by = cl_abap_context_info=>get_user_technical_name( ).

    IF is_conf_log-pid IS NOT INITIAL.

      TRY.

          CONVERT KEY OF i_repetitivemfgconfirmationtp
            FROM TEMPORARY VALUE #(
              %pid = is_conf_log-pid
            ) TO DATA(ls_final_key).

          ls_conf_log-conf_doc = ls_final_key-repetitivemfgconfirmation.
          ls_conf_log-status   = if_abap_behv_message=>severity-success.
          APPEND ls_conf_log TO lt_conf_log.

          UPDATE zpp_t_conf_h
            SET conf_doc = @ls_conf_log-conf_doc
            WHERE conf_uuid = @ls_conf_log-confuuid.

          " Yemek Duruşu Yarat
          IF ls_final_key-repetitivemfgconfirmation IS NOT INITIAL AND
             is_conf_log-downtime = abap_true.
            zcl_pp_conf=>set_downtime_eat( is_conf_log = is_conf_log  ).
          ENDIF.

        CATCH cx_root INTO DATA(lx_key).
          lv_mess = lx_key->get_text( ).
          ls_conf_log-status       = if_abap_behv_message=>severity-error.
          ls_conf_log-message_text = CONV #( lv_mess ).
          APPEND ls_conf_log TO lt_conf_log.
      ENDTRY.


    ELSE.

      DATA(lv_index) = 0.
      LOOP AT is_conf_log-item INTO DATA(ls_log_item).

        CLEAR ls_conf_log.
        ls_conf_log = CORRESPONDING #( is_conf_log ).
        ls_conf_log-log_date   = ls_datetime-datum.
        ls_conf_log-log_time   = ls_datetime-uzeit + lv_index.
        ls_conf_log-created_by = cl_abap_context_info=>get_user_technical_name( ).
        ls_conf_log-message_text = ls_log_item-message_text.
        ls_conf_log-status       = ls_log_item-status.
        APPEND ls_conf_log TO lt_conf_log.
        lv_index += 1.
      ENDLOOP.

    ENDIF.

    IF lt_conf_log[] IS NOT INITIAL.
      MODIFY zpp_t_conf_log FROM TABLE @lt_conf_log.
    ENDIF.

  ENDMETHOD.


  METHOD get_prod_version.

    DATA(lv_material) = CONV matnr( |{ iv_material ALPHA = IN WIDTH = 18 }| ).

    SELECT material,
           plant,
           productionversion,
           billofmaterialvariant
      FROM i_productionversion
      WHERE material = @lv_material
        AND plant    = @iv_plant
        AND ( productionversionstatus = 1 OR
              productionversionstatus IS INITIAL )
        AND bomcheckstatus = 1
      ORDER BY productionversion ASCENDING
      INTO TABLE @DATA(lt_prodvers).

    rs_prod_version = VALUE #( lt_prodvers[ 1 ] OPTIONAL  ).

  ENDMETHOD.


  METHOD get_prod_type.

    DATA(lv_material) = CONV zpp_t_conf_010-malzeme( |{ iv_material ALPHA = IN WIDTH = 18 }| ).

    SELECT SINGLE malzeme, uretimturu FROM zpp_t_conf_010
      WHERE malzeme = @lv_material
      INTO @DATA(ls_prod_type).
    IF sy-subrc = 0.
      rs_prod_type = VALUE #( material   = ls_prod_type-malzeme
                              uretimturu = ls_prod_type-uretimturu ).
    ELSE." Kayıt yoksa defaul üretim tipi
      rs_prod_type = VALUE #( material   = lv_material
                              uretimturu = zcl_pp_conf=>mc_ut_mamul_borek ).
    ENDIF.

  ENDMETHOD.


  METHOD get_charge_quan.

    DATA(lv_material) = CONV matnr( |{ iv_material ALPHA = IN WIDTH = 18 }| ).

    " Şuanlık bu tablo kullanılmayacak gibi görünüyor
*    SELECT SINGLE malzeme, sarjmiktari FROM zpp_t_conf_011
*      WHERE malzeme = @lv_material
*      INTO @rs_charge_quantity.


    DATA(lt_bom_result) = zcl_pp_conf=>explode_bom( iv_material = lv_material iv_quantity = 1 ).
    IF lt_bom_result[] IS NOT INITIAL.
      DATA(ls_bom_header) = VALUE #( lt_bom_result[ 1 ] OPTIONAL ).
      rs_charge_quantity-malzeme     = ls_bom_header-material.
      rs_charge_quantity-sarjmiktari = ls_bom_header-bomheaderquantityinbaseunit.
    ENDIF.

  ENDMETHOD.

  METHOD get_mat_downtime_eat.

    SELECT SINGLE malzeme FROM zpp_t_conf_015
      WHERE malzeme = @iv_material
       INTO @rs_data.

  ENDMETHOD.


  METHOD change_batch_prod_date.
    " Kullanım Dışı
*    DATA: ls_conf_log TYPE zpp_t_conf_log.
*
*    SELECT conf_uuid AS confuuid,
*       shiftcode,
*       groupcode,
*       material,
*       plant,
*       production_batch AS productionbatch
*  FROM zpp_t_conf_h
*  WHERE batch_update     = @abap_false
*    AND material         IS NOT INITIAL
*    AND production_batch IS NOT INITIAL
*    AND conf_doc         IS NOT INITIAL
*  INTO TABLE @DATA(lt_header).
*    IF sy-subrc EQ 0.
*
*      LOOP AT lt_header INTO DATA(ls_header).
*        DATA(lv_material_in) = |{ ls_header-material ALPHA = IN WIDTH = 18 }|.
*        MODIFY ENTITIES OF i_batchtp_2 PRIVILEGED
*         ENTITY batch
*           UPDATE FROM VALUE #(
*             (
*               material = lv_material_in
*               batch    = ls_header-productionbatch
*               manufacturedate = cl_abap_context_info=>get_system_date( )
*               %control-manufacturedate = cl_abap_behv=>flag_changed
*             )
*           )
*         FAILED DATA(failed_batch)
*         REPORTED DATA(reported_batch).
*
*        CLEAR ls_conf_log.
*        ls_conf_log = CORRESPONDING #( ls_header ).
*        ls_conf_log-material = lv_material_in.
*        DATA(ls_datetime) = zcl_pp_conf=>get_local_datetime( ).
*        ls_conf_log-log_date = ls_datetime-datum.
*        ls_conf_log-log_time = ls_datetime-uzeit.
*        ls_conf_log-created_by = cl_abap_context_info=>get_user_technical_name( ).
*
*        LOOP AT reported_batch-batch ASSIGNING FIELD-SYMBOL(<ls_rep_batch>)
*           WHERE %msg IS BOUND.
*          ls_conf_log-status       = <ls_rep_batch>-%msg->m_severity.
*          ls_conf_log-message_text = <ls_rep_batch>-%msg->if_message~get_text( ).
*        ENDLOOP.
*
*        MODIFY zpp_t_conf_log FROM @ls_conf_log.
*
*        IF failed_batch-batch IS INITIAL.
*          UPDATE zpp_t_conf_h
*            SET batch_update = @abap_true
*            WHERE conf_uuid = @ls_header-confuuid.
*        ENDIF.
*
*
*      ENDLOOP.
*
*    ENDIF.

  ENDMETHOD.


  METHOD convert_material_quantity.
    DATA: lv_base_uom        TYPE msehi,
          lv_source_in_base  TYPE zpp_de_quan_l,
          lv_src_numerator   TYPE i_productunitsofmeasure-quantitynumerator,
          lv_src_denominator TYPE i_productunitsofmeasure-quantitydenominator,
          lv_tgt_numerator   TYPE i_productunitsofmeasure-quantitynumerator,
          lv_tgt_denominator TYPE i_productunitsofmeasure-quantitydenominator.

    CLEAR ev_target_qty.

    IF iv_source_uom = iv_target_uom.
      ev_target_qty = iv_source_qty.
      RETURN.
    ENDIF.

    SELECT SINGLE baseunit FROM i_product
      WHERE product = @iv_product
      INTO @lv_base_uom.

    IF sy-subrc NE 0.
      RETURN.
    ENDIF.

    IF iv_source_uom = lv_base_uom.
      lv_source_in_base = iv_source_qty.
    ELSE.
      SELECT SINGLE quantitynumerator, quantitydenominator FROM i_productunitsofmeasure
        WHERE product = @iv_product AND alternativeunit = @iv_source_uom
        INTO ( @lv_src_numerator, @lv_src_denominator ).

      IF sy-subrc NE 0.
        RETURN.
      ENDIF.

      lv_source_in_base = ( iv_source_qty * lv_src_numerator ) / lv_src_denominator.
    ENDIF.

    IF iv_target_uom = lv_base_uom.
      ev_target_qty = lv_source_in_base.
    ELSE.
      SELECT SINGLE quantitynumerator, quantitydenominator FROM i_productunitsofmeasure
        WHERE product = @iv_product AND alternativeunit = @iv_target_uom
        INTO ( @lv_tgt_numerator, @lv_tgt_denominator ).

      IF sy-subrc NE 0.
        RETURN.
      ENDIF.

      ev_target_qty = ( lv_source_in_base * lv_tgt_denominator ) / lv_tgt_numerator.
    ENDIF.
  ENDMETHOD.


  METHOD get_bom_item_cat.

    CLEAR rv_bomitemcat.

    DATA(lv_material) = CONV matnr(
      |{ iv_material ALPHA = IN WIDTH = 18 }|
    ).

    DATA(lv_component) = CONV matnr(
      |{ iv_component ALPHA = IN WIDTH = 18 }|
    ).

    IF lv_material IS INITIAL
    OR lv_component IS INITIAL.
      RETURN.
    ENDIF.

    DATA(ls_prodver) = zcl_pp_conf=>get_prod_version(
      iv_material = lv_material
      iv_plant    = iv_plant
    ).

    IF ls_prodver-billofmaterialvariant IS INITIAL.
      RETURN.
    ENDIF.

    DATA(ls_datetime) = zcl_pp_conf=>get_local_datetime( ).

    SELECT item~billofmaterialitemcategory
  FROM i_materialbomlink AS link
  INNER JOIN i_billofmaterialitembasic AS item
    ON  item~billofmaterialcategory = link~billofmaterialcategory
    AND item~billofmaterial         = link~billofmaterial
  WHERE link~material                     = @lv_material
    AND link~plant                        = @iv_plant
    AND link~billofmaterialvariant        = @ls_prodver-billofmaterialvariant
    AND link~billofmaterialvariantusage   = @zcl_pp_conf=>mc_default_bom_usage
    AND link~billofmaterialcategory       = @zcl_pp_conf=>mc_billofmaterialcategory
    AND item~billofmaterialcomponent      = @lv_component
    AND item~billofmaterialcategory       = @zcl_pp_conf=>mc_billofmaterialcategory
    AND item~validitystartdate            <= @ls_datetime-datum
    AND item~validityenddate              >= @ls_datetime-datum
    AND item~isdeleted                    = ''
  ORDER BY item~billofmaterialitemnumber
  INTO @rv_bomitemcat
  UP TO 1 ROWS.
    ENDSELECT.

  ENDMETHOD.
ENDCLASS.
