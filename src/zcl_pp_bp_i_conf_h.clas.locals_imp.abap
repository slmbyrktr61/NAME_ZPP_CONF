CLASS lcl_buffer DEFINITION FINAL CREATE PRIVATE.
  PUBLIC SECTION.

    CLASS-DATA: gt_dwntm                  TYPE STANDARD TABLE OF zpp_t_conf_dwntm WITH EMPTY KEY,
                gs_conf_log               TYPE zcl_pp_conf=>ty_conf_log_h,
                gv_skip_fillcomponentdata TYPE abap_boolean.
ENDCLASS.

CLASS lcl_buffer IMPLEMENTATION.
ENDCLASS.


CLASS lsc_zpp_i_conf_h DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.


CLASS lsc_zpp_i_conf_h IMPLEMENTATION.

  METHOD save_modified.

    """""""" Teyit Belgesi Logla
    IF lcl_buffer=>gs_conf_log IS NOT INITIAL.
      zcl_pp_conf=>save_conf_log( is_conf_log = lcl_buffer=>gs_conf_log ).
    ENDIF.

    """""""" Duruş Kayıtlarını Kaydet
    IF lcl_buffer=>gt_dwntm IS NOT INITIAL.
      MODIFY zpp_t_conf_dwntm FROM TABLE @lcl_buffer=>gt_dwntm.
    ENDIF.

  ENDMETHOD.

  METHOD cleanup_finalize.

    CLEAR: lcl_buffer=>gt_dwntm , lcl_buffer=>gs_conf_log, lcl_buffer=>gv_skip_fillcomponentdata.

  ENDMETHOD.

ENDCLASS.


CLASS lhc__header DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR _header RESULT result.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR _header RESULT result.

    METHODS fillmaterialdata FOR DETERMINE ON MODIFY
      IMPORTING keys FOR _header~fillmaterialdata.

    METHODS setproductionbatch FOR DETERMINE ON MODIFY
      IMPORTING keys FOR _header~setproductionbatch.

    METHODS getmatcomponents FOR MODIFY
      IMPORTING keys FOR ACTION _header~getmatcomponents RESULT result.

    METHODS downtimereason FOR MODIFY
      IMPORTING keys FOR ACTION _header~downtimereason RESULT result.

    METHODS confirmation FOR MODIFY
      IMPORTING keys FOR ACTION _header~confirmation RESULT result.

    METHODS getprodquan FOR MODIFY
      IMPORTING keys FOR ACTION _header~getprodquan RESULT result.

    METHODS definebatch FOR MODIFY
      IMPORTING keys FOR ACTION _header~definebatch RESULT result.

    METHODS changeproductionquan FOR DETERMINE ON MODIFY
      IMPORTING keys FOR _header~changeproductionquan.

    METHODS setclosingshiftvisibility FOR DETERMINE ON MODIFY
      IMPORTING keys FOR _header~setclosingshiftvisibility.

    METHODS validatemandatoryheader FOR VALIDATE ON SAVE
      IMPORTING keys FOR _header~validatemandatoryheader.

*    METHODS validatemandatoryitems FOR VALIDATE ON SAVE
*      IMPORTING keys FOR _header~validatemandatoryitems.

    METHODS usescrapmaterial FOR MODIFY
      IMPORTING keys FOR ACTION _header~usescrapmaterial RESULT result.
    METHODS setchargequantityvisibility FOR DETERMINE ON MODIFY

      IMPORTING keys FOR _header~setchargequantityvisibility.

*    METHODS setchargequanvisibilitysave FOR DETERMINE ON SAVE
*      IMPORTING keys FOR _header~setchargequanvisibilitysave.

ENDCLASS.

CLASS lhc__item DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

*    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
*      IMPORTING keys REQUEST requested_authorizations FOR _item RESULT result.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR _item RESULT result.

    METHODS fillcomponentdata FOR DETERMINE ON MODIFY
      IMPORTING keys FOR _item~fillcomponentdata.

    METHODS changequantitybycarcount FOR DETERMINE ON MODIFY
      IMPORTING keys FOR _item~changequantitybycarcount.

    METHODS changequantitybyactualstock FOR DETERMINE ON MODIFY
      IMPORTING keys FOR _item~changequantitybyactualstock.



ENDCLASS.


CLASS lhc__header IMPLEMENTATION.

  METHOD usescrapmaterial.

    TYPES: BEGIN OF ty_scrap,
             product           TYPE matnr,
             additionalproduct TYPE matnr,
           END OF ty_scrap.

    TYPES: BEGIN OF ty_stock_sum,
             product         TYPE matnr,
             storagelocation TYPE zpp_i_batch_stock_vh-storagelocation,
             stockqty        TYPE zpp_i_batch_stock_vh-stockqty,
           END OF ty_stock_sum.

    DATA: lt_update        TYPE TABLE FOR UPDATE zpp_i_conf_i,
          lt_scrap         TYPE STANDARD TABLE OF ty_scrap WITH EMPTY KEY,
          lt_stock_sum     TYPE STANDARD TABLE OF ty_stock_sum WITH EMPTY KEY,
          lt_stock_product TYPE SORTED TABLE OF matnr WITH UNIQUE KEY table_line,
          lv_has_error     TYPE abap_boolean.

    " Başlık ve kalemler okunur
    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _header
        FIELDS (
          confuuid
          material
          productiontype
          closingshift
          confdoc
        )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_header)

      ENTITY _header BY \_items
        FIELDS (
          itemuuid
          confuuid
          componentmaterial
          componentdescription
          storagelocation
          quantity
          unit
          bomitemcat
        )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_item).

    READ TABLE lt_header ASSIGNING FIELD-SYMBOL(<ls_header>) INDEX 1.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    " Koşul kontrolü
    IF <ls_header>-confdoc IS NOT INITIAL
    OR <ls_header>-closingshift = abap_true
    OR NOT ( <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_borek
          OR <ls_header>-productiontype = zcl_pp_conf=>mc_ut_mamul_ee_lahmacun
          OR <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_ee_lahmacun ).

      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.

      APPEND VALUE #(
        %tky = <ls_header>-%tky
        %msg = new_message(
          id       = zcl_pp_conf=>mc_mess_id
          number   = '039'
          severity = if_abap_behv_message=>severity-error
        )
      ) TO reported-_header.

      RETURN.

    ENDIF.

    IF lt_item IS INITIAL.

      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.

      APPEND VALUE #(
        %tky = <ls_header>-%tky
        %msg = new_message(
          id       = zcl_pp_conf=>mc_mess_id
          number   = '040'
          severity = if_abap_behv_message=>severity-error
        )
      ) TO reported-_header.

      RETURN.

    ENDIF.

    " Ana bileşenler: Z kalem ve miktar 0
    DATA lt_main_item LIKE lt_item.

    LOOP AT lt_item INTO DATA(ls_item_main)
      WHERE bomitemcat = zcl_pp_conf=>mc_bomitemcat_z
        AND quantity   = 0.
      APPEND ls_item_main TO lt_main_item.
    ENDLOOP.

    IF lt_main_item IS INITIAL.

      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.

      APPEND VALUE #(
        %tky = <ls_header>-%tky
        %msg = new_message(
          id       = zcl_pp_conf=>mc_mess_id
          number   = '041'
          severity = if_abap_behv_message=>severity-error
        )
      ) TO reported-_header.

      RETURN.

    ENDIF.

    " Iskarta eşleşmeleri okunur
    SELECT material,
           scrap_material
      FROM zpp_t_conf_012
      FOR ALL ENTRIES IN @lt_main_item
      WHERE material = @lt_main_item-componentmaterial
      INTO TABLE @lt_scrap.

    IF lt_scrap IS INITIAL.

      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.

      APPEND VALUE #(
        %tky = <ls_header>-%tky
        %msg = new_message(
          id       = zcl_pp_conf=>mc_mess_id
          number   = '042'
          severity = if_abap_behv_message=>severity-error
        )
      ) TO reported-_header.

      RETURN.

    ENDIF.

    " Stok için ana ve ıskarta malzemeleri hazırlanır
    LOOP AT lt_main_item ASSIGNING FIELD-SYMBOL(<ls_main_stock_key>).
      INSERT CONV matnr( |{ <ls_main_stock_key>-componentmaterial ALPHA = IN WIDTH = 18 }| ) INTO TABLE lt_stock_product.
    ENDLOOP.

    LOOP AT lt_scrap ASSIGNING FIELD-SYMBOL(<ls_add_stock_key>).
      IF <ls_add_stock_key>-additionalproduct IS NOT INITIAL.
        INSERT CONV matnr( |{ <ls_add_stock_key>-additionalproduct ALPHA = IN WIDTH = 18 }| ) INTO TABLE lt_stock_product.
      ENDIF.
    ENDLOOP.

    " Sadece ilgili malzemelerin stokları toplanır
    IF lt_stock_product IS NOT INITIAL.

      SELECT s~product,
             s~storagelocation,
             SUM( s~stockqty ) AS stockqty
        FROM zpp_i_batch_stock_vh AS s
        INNER JOIN @lt_stock_product AS p
          ON p~table_line = s~product
        GROUP BY s~product,
                 s~storagelocation
        INTO TABLE @lt_stock_sum.

    ENDIF.

    " Ana bileşen ve ıskarta miktarları hesaplanır
    LOOP AT lt_main_item ASSIGNING FIELD-SYMBOL(<ls_main>).

      DATA(lv_main_product)    = CONV matnr( |{ <ls_main>-componentmaterial ALPHA = IN WIDTH = 18 }| ).
      DATA(lv_header_material) = CONV matnr( |{ <ls_header>-material ALPHA = IN WIDTH = 18 }| ).
      DATA(lv_main_stock)      = VALUE zpp_i_batch_stock_vh-stockqty(
        lt_stock_sum[
          product         = lv_main_product
          storagelocation = <ls_main>-storagelocation
        ]-stockqty OPTIONAL
      ).

      " Sabit stok miktarı okunur
      SELECT SINGLE stkklnsabitmik
        FROM zpp_t_conf_006
        WHERE yarimamul    = @lv_header_material
          AND altyarimamul = @lv_main_product
        INTO @DATA(lv_sabit_mik).

      IF sy-subrc <> 0.

        APPEND VALUE #( %tky = <ls_main>-%tky ) TO failed-_item.

        APPEND VALUE #(
          %tky = <ls_main>-%tky
          %msg = new_message(
            id       = zcl_pp_conf=>mc_mess_id
            number   = '043'
            severity = if_abap_behv_message=>severity-error
            v1       = |{ <ls_main>-componentmaterial ALPHA = OUT }|
          )
        ) TO reported-_item.

        lv_has_error = abap_true.
        CONTINUE.

      ENDIF.

      LOOP AT lt_scrap ASSIGNING FIELD-SYMBOL(<ls_add>).

        DATA(lv_add_product) = CONV matnr( |{ <ls_add>-product ALPHA = IN WIDTH = 18 }| ).

        IF lv_add_product <> lv_main_product.
          CONTINUE.
        ENDIF.

        DATA(lv_scrap_product) = CONV matnr( |{ <ls_add>-additionalproduct ALPHA = IN WIDTH = 18 }| ).

        LOOP AT lt_item ASSIGNING FIELD-SYMBOL(<ls_scrap>)
          WHERE bomitemcat <> zcl_pp_conf=>mc_bomitemcat_z.

          DATA(lv_scrap_item_product) = CONV matnr( |{ <ls_scrap>-componentmaterial ALPHA = IN WIDTH = 18 }| ).

          IF lv_scrap_item_product <> lv_scrap_product.
            CONTINUE.
          ENDIF.

          DATA(lv_scrap_stock) = VALUE zpp_i_batch_stock_vh-stockqty(
            lt_stock_sum[
              product         = lv_scrap_product
              storagelocation = <ls_scrap>-storagelocation
            ]-stockqty OPTIONAL
          ).

          " Toplam Stok = ana stok + ıskarta stok
          DATA(lv_total_stock) = CONV zpp_i_conf_i-quantity( lv_main_stock + lv_scrap_stock ).

          " Genel Stok = Toplam Stok - sabit miktar
          DATA(lv_gen_stock) = CONV zpp_i_conf_i-quantity( lv_total_stock - lv_sabit_mik ).

          " Ana bileşen kalan miktar
          DATA(lv_sub_stock)      = CONV zpp_i_conf_i-quantity( lv_gen_stock - lv_main_stock ).
          DATA(lv_scrap_quantity) = COND #( WHEN lv_sub_stock < 0 THEN 0 ELSE lv_sub_stock ).
          DATA(lv_main_quantity)  = COND #( WHEN lv_main_stock >= lv_gen_stock THEN lv_gen_stock ELSE lv_main_stock ).

          " Negatif/hesaplanamayan sonuçta işlem durdurulur
          IF lv_scrap_quantity = 0
         AND lv_main_quantity  = 0.

            APPEND VALUE #( %tky = <ls_main>-%tky ) TO failed-_item.
            APPEND VALUE #( %tky = <ls_scrap>-%tky ) TO failed-_item.

            APPEND VALUE #(
              %tky = <ls_main>-%tky
              %msg = new_message(
                id       = zcl_pp_conf=>mc_mess_id
                number   = '044'
                severity = if_abap_behv_message=>severity-error
                v1       = |{ <ls_main>-componentmaterial ALPHA = OUT }|
                v2       = |{ <ls_scrap>-componentmaterial ALPHA = OUT }|
              )
            ) TO reported-_item.

            lv_has_error = abap_true.
            CONTINUE.

          ENDIF.

          " Ana bileşen update tekilleştirilir
          READ TABLE lt_update ASSIGNING FIELD-SYMBOL(<ls_upd_main>)
            WITH KEY %tky = <ls_main>-%tky.

          IF sy-subrc = 0.
            <ls_upd_main>-quantity = lv_main_quantity.
          ELSE.
            APPEND VALUE #(
              %tky    = <ls_main>-%tky
              quantity = lv_main_quantity
            ) TO lt_update.
          ENDIF.

          " Iskarta update tekilleştirilir
          READ TABLE lt_update ASSIGNING FIELD-SYMBOL(<ls_upd_scrap>)
            WITH KEY %tky = <ls_scrap>-%tky.

          IF sy-subrc = 0.
            <ls_upd_scrap>-quantity = lv_scrap_quantity.
          ELSE.
            APPEND VALUE #(
              %tky    = <ls_scrap>-%tky
              quantity = lv_scrap_quantity
            ) TO lt_update.
          ENDIF.

        ENDLOOP.

      ENDLOOP.

    ENDLOOP.

    " Hata varsa update yapılmaz
    IF lv_has_error = abap_true.
      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
      RETURN.
    ENDIF.

    IF lt_update IS INITIAL.

      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.

      APPEND VALUE #(
        %tky = <ls_header>-%tky
        %msg = new_message(
          id       = zcl_pp_conf=>mc_mess_id
          number   = '045'
          severity = if_abap_behv_message=>severity-error
        )
      ) TO reported-_header.

      RETURN.

    ENDIF.

    " Kalem miktarları güncellenir
    MODIFY ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _item
        UPDATE FIELDS ( quantity )
        WITH lt_update
      REPORTED DATA(lt_reported_update)
      FAILED DATA(lt_failed_update).

    IF lt_failed_update-_item IS NOT INITIAL.

      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.

      APPEND VALUE #(
        %tky = <ls_header>-%tky
        %msg = new_message(
          id       = zcl_pp_conf=>mc_mess_id
          number   = '046'
          severity = if_abap_behv_message=>severity-error
        )
      ) TO reported-_header.

      RETURN.

    ENDIF.

    APPEND VALUE #(
      %tky = <ls_header>-%tky
      %msg = new_message(
        id       = zcl_pp_conf=>mc_mess_id
        number   = '047'
        severity = if_abap_behv_message=>severity-success
      )
    ) TO reported-_header.

    " Güncel başlık sonucu döndürülür
    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _header
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #(
      FOR ls_result IN lt_result
      (
        %tky   = ls_result-%tky
        %param = ls_result
      )
    ).

  ENDMETHOD.


*  METHOD confirmation.
*
*    DATA lv_timestamp  TYPE timestampl.
*    DATA lv_user_tzone TYPE timezone.
*    DATA lv_user_date  TYPE d.
*    DATA lv_user_time  TYPE t.
*
*    DATA: lv_mess       TYPE string,
*          lv_error_flag.
*    DATA lt_material TYPE SORTED TABLE OF matnr WITH UNIQUE KEY table_line.
*
*    CLEAR: lcl_buffer=>gs_conf_log. " Log verisi tut
*
*    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
*      ENTITY _header
*        ALL FIELDS
*        WITH CORRESPONDING #( keys )
*        RESULT DATA(lt_header)
*      ENTITY _header BY \_items
*        ALL FIELDS
*        WITH CORRESPONDING #( keys )
*        RESULT DATA(lt_item).
*
*
*    """"""""""""""""""""""" BAŞLIK KONTROLLERİ """""""""""""""""""""""
*    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
*
*    READ TABLE keys ASSIGNING FIELD-SYMBOL(<ls_key>) INDEX 1.
*    IF lt_header[] IS INITIAL.
*      APPEND VALUE #( %tky = <ls_key>-%tky ) TO failed-_header.
*      APPEND VALUE #( %tky = <ls_key>-%tky %msg = new_message( id = zcl_pp_conf=>mc_mess_id number = '002' severity = if_abap_behv_message=>severity-error ) ) TO reported-_header.
*      RETURN.
*    ENDIF.
*
*    DATA(ls_header) = VALUE #( lt_header[ 1 ] OPTIONAL ).
*    IF ls_header-material IS INITIAL OR
**       ls_header-productionquantity IS INITIAL OR
*       ls_header-baseunit IS INITIAL.
*      APPEND VALUE #( %tky = <ls_key>-%tky ) TO failed-_header.
*      APPEND VALUE #( %tky = <ls_key>-%tky %msg = new_message( id = zcl_pp_conf=>mc_mess_id number = '002' severity = if_abap_behv_message=>severity-error ) ) TO reported-_header.
*      RETURN.
*    ENDIF.
*
*    IF ls_header-productiontype = zcl_pp_conf=>mc_ut_ym_borek AND
*        ls_header-multiplier IS INITIAL.
*      APPEND VALUE #( %tky = ls_header-%tky ) TO failed-_header.
*      APPEND VALUE #(  %tky = ls_header-%tky %element-multiplier = if_abap_behv=>mk-on
*          %msg = new_message(  id = zcl_pp_conf=>mc_mess_id number = '037' severity = if_abap_behv_message=>severity-error v1 = ls_header-productiontype ) ) TO reported-_header.
*      RETURN.
*    ENDIF.
*
*
*    """"""""""""""""""""""" KALEM KONTROLLERİ """""""""""""""""""""""
*    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
*
*    IF lt_item[] IS INITIAL.
*      APPEND VALUE #( %tky = <ls_key>-%tky ) TO failed-_header.
*      APPEND VALUE #( %tky = <ls_key>-%tky %msg = new_message( id = zcl_pp_conf=>mc_mess_id number = '001' severity = if_abap_behv_message=>severity-error ) ) TO reported-_header.
*      RETURN.
*    ENDIF.
*
*    " Bileşen Malzemeler dolu ise stoklara bak
*    CLEAR lt_material.
*
*    LOOP AT lt_item ASSIGNING FIELD-SYMBOL(<ls_item_mat>)
*      WHERE componentmaterial IS NOT INITIAL.
*
*      INSERT CONV matnr(
*        |{ <ls_item_mat>-componentmaterial ALPHA = IN WIDTH = 18 }|
*      ) INTO TABLE lt_material.
*
*    ENDLOOP.
*
*    IF lt_material IS NOT INITIAL.
*
*      SELECT s~batch,
*             s~storagelocation,
*             s~product
*        FROM zpp_i_batch_stock_vh AS s
*        INNER JOIN @lt_material AS i
*          ON i~table_line = s~product
*        INTO TABLE @DATA(lt_stock).
*
*    ENDIF.
*
*
*    " Kalem kontrolleri
*    LOOP AT lt_item INTO DATA(ls_check).
*
*      DATA(lv_comp_mat) = |{ ls_check-componentmaterial ALPHA = OUT }|.
*      DATA(lv_comp_mat_in) = |{ ls_check-componentmaterial ALPHA = IN WIDTH = 18 }|.
*
*      " Zorunlu alan kontrolleri
*      IF ls_check-componentmaterial IS INITIAL.
*        APPEND VALUE #( %tky = ls_check-%tky  ) TO failed-_item.
*        APPEND VALUE #( %tky = ls_check-%tky %msg = new_message( id = zcl_pp_conf=>mc_mess_id number = '003' severity = if_abap_behv_message=>severity-error ) ) TO reported-_item.
*        lv_error_flag = abap_true.
*      ENDIF.
*
*      IF ls_check-storagelocation IS INITIAL.
*        APPEND VALUE #( %tky = ls_check-%tky ) TO failed-_item.
*        APPEND VALUE #( %tky = ls_check-%tky %msg = new_message( id = zcl_pp_conf=>mc_mess_id number = '013' severity = if_abap_behv_message=>severity-error v1 = lv_comp_mat ) ) TO reported-_item.
*        lv_error_flag = abap_true.
*      ENDIF.
*      IF ls_check-batch IS INITIAL AND ls_check-isbatchmngmntrequired EQ abap_true. " parti ilişkilimi
*        APPEND VALUE #( %tky = ls_check-%tky ) TO failed-_item.
*        APPEND VALUE #( %tky = ls_check-%tky %msg = new_message( id = zcl_pp_conf=>mc_mess_id number = '014' severity = if_abap_behv_message=>severity-error v1 = lv_comp_mat ) ) TO reported-_item.
*        lv_error_flag = abap_true.
*      ENDIF.
*      IF ls_check-quantity IS INITIAL.
*        APPEND VALUE #( %tky = ls_check-%tky ) TO failed-_item.
*        APPEND VALUE #( %tky = ls_check-%tky %msg = new_message( id = zcl_pp_conf=>mc_mess_id number = '015' severity = if_abap_behv_message=>severity-error v1 = lv_comp_mat ) ) TO reported-_item.
*        lv_error_flag = abap_true.
*      ENDIF.
*
*      " Stok yok ise hata ver
*      IF ls_check-componentmaterial IS NOT INITIAL AND
*         ls_check-storagelocation IS NOT INITIAL AND
*         ls_check-batch IS NOT INITIAL AND
*         NOT line_exists( lt_stock[ batch = ls_check-batch storagelocation = ls_check-storagelocation product = lv_comp_mat_in ] ).
*        APPEND VALUE #( %tky = ls_check-%tky ) TO failed-_item.
*        APPEND VALUE #( %tky = ls_check-%tky %msg = new_message( id = zcl_pp_conf=>mc_mess_id number = '016' severity = if_abap_behv_message=>severity-error
*         v1 = lv_comp_mat v2 = ls_check-storagelocation v3 =  |{ ls_check-batch ALPHA = OUT }| ) ) TO reported-_item.
*        lv_error_flag = abap_true.
*      ENDIF.
*
*    ENDLOOP.
*    IF lv_error_flag = abap_true.
*      IF failed-_header IS INITIAL.
*        APPEND VALUE #( %tky = ls_header-%tky ) TO failed-_header.
*      ENDIF.
*      EXIT.
*    ENDIF.
*
*
*
*    """"""""""""""""""""""" BO BAŞLIK KONTROLLERİ """""""""""""""""""""""
*    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
*
*    DATA(lv_material) = CONV matnr( |{ ls_header-material ALPHA = IN WIDTH = 18 }| ).
*    DATA(lv_conftext) = |{ ls_header-shiftcode+1(1) }{ ls_header-groupcode }|.
*
*
*    GET TIME STAMP FIELD lv_timestamp.
*    TRY.
*        CONVERT TIME STAMP lv_timestamp
*         TIME ZONE cl_abap_context_info=>get_user_time_zone( )
*         INTO DATE DATA(lv_date).
*      CATCH cx_abap_context_info_error.
*        APPEND VALUE #( %tky = <ls_key>-%tky ) TO failed-_header.
*        APPEND VALUE #( %tky = <ls_key>-%tky %msg =
*        new_message( id = zcl_pp_conf=>mc_mess_id number = '017' severity = if_abap_behv_message=>severity-error ) ) TO reported-_header.
*        RETURN.
*    ENDTRY.
*
*
*
*    " UOM Conversion
*    SELECT SINGLE unitofmeasureisocode FROM i_unitofmeasure
*     WHERE unitofmeasure = @ls_header-baseunit
*      INTO @DATA(lv_uom).
*    IF sy-subrc NE 0.
*      APPEND VALUE #( %tky = <ls_key>-%tky ) TO failed-_header.
*      APPEND VALUE #( %tky = <ls_key>-%tky %msg =
*      new_message( id = zcl_pp_conf=>mc_mess_id number = '007' severity = if_abap_behv_message=>severity-error v1 = ls_header-material v2 = ls_header-baseunit ) ) TO reported-_header.
*      RETURN.
*    ENDIF.
*
*    " Production Version & BOM Variant
*    DATA(ls_prodver) = zcl_pp_conf=>get_prod_version( iv_material = lv_material iv_plant = zcl_pp_conf=>mc_plant ).
*    IF ls_prodver-productionversion IS INITIAL OR ls_prodver-billofmaterialvariant IS INITIAL.
*      APPEND VALUE #( %tky = <ls_key>-%tky ) TO failed-_header.
*      APPEND VALUE #( %tky = <ls_key>-%tky %msg =
*       new_message( id = zcl_pp_conf=>mc_mess_id number = '004' severity = if_abap_behv_message=>severity-error v1 = ls_header-material ) ) TO reported-_header.
*      RETURN.
*    ENDIF.
*
*    " Production Quantity
*    IF ls_header-productiontype = zcl_pp_conf=>mc_ut_ym_borek AND
*        ls_header-multiplier IS NOT INITIAL.
*      ls_header-productionquantity = ls_header-productionquantity * ls_header-multiplier.
*    ENDIF.
*
*
*
*    """"""""""""""""""""""" BO Create Confirmation """""""""""""""""""""
*    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
*
*    MODIFY ENTITIES OF i_repetitivemfgconfirmationtp PRIVILEGED
*      ENTITY repetitivemfgconfirmation
*        CREATE SET FIELDS WITH VALUE #( (
*            %cid = 'CONF_1'
*            repetitivemfgconfscenario      = '01'
*            rptvmfgconfprocessingtype      = 'B'
*            confirmationentryquantity      = ls_header-productionquantity
*            confirmationunitisocode        = lv_uom
*            productionplant                = zcl_pp_conf=>mc_plant
*            receivingbatch                 = ls_header-productionbatch
*            postingdate                    = lv_date
*            documentdate                   = lv_date
*            product                        = lv_material
*            productionversion              = ls_prodver-productionversion
*            repetitivemfgconfirmationtext  = lv_conftext  )  )
*      ENTITY repetitivemfgconfirmation
*        CREATE BY \_rptvmfgconfmatldocitemtp
*        SET FIELDS WITH VALUE #( (
*            %cid_ref = 'CONF_1'
*            %target = VALUE #(
*              FOR ls_item IN lt_item INDEX INTO lv_index
*              (
*                %cid = |GM_{ lv_index }| material = CONV matnr( |{ ls_item-componentmaterial ALPHA = IN WIDTH = 18 }| )
*                plant               = ls_header-plant
*                storagelocation     = ls_item-storagelocation
*                goodsmovementtype   = '261'
*                entryunitsapcode    = ls_item-unit
*                quantityinentryunit = ls_item-quantity
*                batch               = COND #( WHEN ls_item-isbatchmngmntrequired EQ abap_true THEN ls_item-batch ELSE '' )
*              )  )  )  )
*      MAPPED DATA(mapped_conf)
*      FAILED DATA(failed_conf)
*      REPORTED DATA(reported_conf).
*
*    DATA(ls_mapped_conf) = VALUE #( mapped_conf-repetitivemfgconfirmation[ 1 ] OPTIONAL ).
*
*
*    """"""""""""""""""""""""" DATA LOG """""""""""""""""""""""""
*    lcl_buffer=>gs_conf_log = VALUE  #( confuuid           = ls_header-confuuid
*                                        shiftcode          = ls_header-shiftcode
*                                        groupcode          = ls_header-groupcode
*                                        material           = lv_material
*                                        productionquantity = ls_header-productionquantity
*                                        baseunit           = lv_uom
*                                        productionbatch    = ls_header-productionbatch
*                                        productionversion  = ls_prodver-productionversion
*                                        plant              = ls_header-plant ).
*
*    IF failed_conf IS NOT INITIAL. " ERROR
*      APPEND VALUE #( %tky = <ls_key>-%tky ) TO failed-_header.
*      LOOP AT reported_conf-repetitivemfgconfirmation ASSIGNING FIELD-SYMBOL(<ls_rep_conf>)
*        WHERE %msg IS BOUND.
*        APPEND VALUE #( %tky = <ls_key>-%tky %msg = <ls_rep_conf>-%msg ) TO reported-_header.
*        APPEND INITIAL LINE TO lcl_buffer=>gs_conf_log-item ASSIGNING FIELD-SYMBOL(<lfs_log_i>).
*        <lfs_log_i>-status = if_abap_behv_message=>severity-error.
*        <lfs_log_i>-message_text = <ls_rep_conf>-%msg->if_message~get_text( ).
*      ENDLOOP.
*      LOOP AT reported_conf-rptvmfgconfmatldocitem ASSIGNING FIELD-SYMBOL(<ls_rep_item>)
*        WHERE %msg IS BOUND.
*        APPEND VALUE #( %tky = <ls_key>-%tky %msg = <ls_rep_item>-%msg ) TO reported-_header.
*        APPEND INITIAL LINE TO lcl_buffer=>gs_conf_log-item ASSIGNING <lfs_log_i>.
*        <lfs_log_i>-status = if_abap_behv_message=>severity-error.
*        <lfs_log_i>-message_text = <ls_rep_item>-%msg->if_message~get_text( ).
*      ENDLOOP.
*      IF reported-_header IS INITIAL.
*        APPEND VALUE #( %tky = <ls_key>-%tky %msg = new_message( id = zcl_pp_conf=>mc_mess_id number = '006' severity = if_abap_behv_message=>severity-error ) ) TO reported-_header.
*        APPEND INITIAL LINE TO lcl_buffer=>gs_conf_log-item ASSIGNING <lfs_log_i>.
*        <lfs_log_i>-status = if_abap_behv_message=>severity-error.
*        MESSAGE ID zcl_pp_conf=>mc_mess_id TYPE 'E' NUMBER '006' INTO lv_mess.
*        <lfs_log_i>-message_text = lv_mess.
*      ENDIF.
*      RETURN.
*
*    ELSE. " SUCCESS
*
*      """"""""""""""""""""""""" Teyit Belgesi için PID i Logluyoruz """""""""""""""""""""""""
*      IF ls_mapped_conf-%pid IS NOT INITIAL.
*        lcl_buffer=>gs_conf_log-pid = ls_mapped_conf-%pid.
*        APPEND VALUE #( %tky = <ls_key>-%tky %msg = new_message( id = zcl_pp_conf=>mc_mess_id number = '008' severity = if_abap_behv_message=>severity-success ) ) TO reported-_header.
*      ENDIF.
*
*      LOOP AT reported_conf-repetitivemfgconfirmation ASSIGNING FIELD-SYMBOL(<ls_rep_success>)
*        WHERE %msg IS BOUND.
*        APPEND VALUE #( %tky = ls_header-%tky %msg = <ls_rep_success>-%msg ) TO reported-_header.
*      ENDLOOP.
*
*    ENDIF.
*
*
*    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
*      ENTITY _header
*        ALL FIELDS
*        WITH CORRESPONDING #( keys )
*      RESULT DATA(lt_result).
*
*    result = VALUE #(
*      FOR ls_result IN lt_result
*      (
*        %tky   = ls_result-%tky
*        %param = ls_result
*      )
*    ).
*
*  ENDMETHOD.


  METHOD confirmation.

    DATA lv_timestamp TYPE timestampl.

    DATA: lv_mess       TYPE string,
          lv_error_flag TYPE abap_boolean.

    DATA lt_material TYPE SORTED TABLE OF matnr WITH UNIQUE KEY table_line.

    CLEAR: lcl_buffer=>gs_conf_log.

    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _header
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_header)

      ENTITY _header BY \_items
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_item).

    """"""""""""""""""""""" BAŞLIK KONTROLLERİ """""""""""""""""""""""

    READ TABLE keys ASSIGNING FIELD-SYMBOL(<ls_key>) INDEX 1.

    IF lt_header IS INITIAL.

      APPEND VALUE #( %tky = <ls_key>-%tky ) TO failed-_header.

      APPEND VALUE #(
        %tky = <ls_key>-%tky
        %msg = new_message(
          id       = zcl_pp_conf=>mc_mess_id
          number   = '002'
          severity = if_abap_behv_message=>severity-error
        )
      ) TO reported-_header.

      RETURN.

    ENDIF.

    DATA(ls_header) = VALUE #( lt_header[ 1 ] OPTIONAL ).

    IF ls_header-material IS INITIAL
    OR ls_header-baseunit IS INITIAL.

      APPEND VALUE #( %tky = <ls_key>-%tky ) TO failed-_header.

      APPEND VALUE #(
        %tky = <ls_key>-%tky
        %msg = new_message(
          id       = zcl_pp_conf=>mc_mess_id
          number   = '002'
          severity = if_abap_behv_message=>severity-error
        )
      ) TO reported-_header.

      RETURN.

    ENDIF.

    IF ls_header-productiontype = zcl_pp_conf=>mc_ut_ym_borek
    AND ls_header-multiplier IS INITIAL.

      APPEND VALUE #( %tky = ls_header-%tky ) TO failed-_header.

      APPEND VALUE #(
        %tky = ls_header-%tky
        %element-multiplier = if_abap_behv=>mk-on
        %msg = new_message(
          id       = zcl_pp_conf=>mc_mess_id
          number   = '037'
          severity = if_abap_behv_message=>severity-error
          v1       = ls_header-productiontype
        )
      ) TO reported-_header.

      RETURN.

    ENDIF.

    """"""""""""""""""""""" KALEM KONTROLLERİ """""""""""""""""""""""

    IF lt_item IS INITIAL.

      APPEND VALUE #( %tky = <ls_key>-%tky ) TO failed-_header.

      APPEND VALUE #(
        %tky = <ls_key>-%tky
        %msg = new_message(
          id       = zcl_pp_conf=>mc_mess_id
          number   = '001'
          severity = if_abap_behv_message=>severity-error
        )
      ) TO reported-_header.

      RETURN.

    ENDIF.

    " Sadece parti yönetimli bileşenler için stok/parti bilgisi okunur
    CLEAR lt_material.

    LOOP AT lt_item ASSIGNING FIELD-SYMBOL(<ls_item_mat>)
      WHERE componentmaterial IS NOT INITIAL
        AND isbatchmngmntrequired = abap_true.

      INSERT CONV matnr(
        |{ <ls_item_mat>-componentmaterial ALPHA = IN WIDTH = 18 }|
      ) INTO TABLE lt_material.

    ENDLOOP.

    IF lt_material IS NOT INITIAL.

      SELECT s~batch,
             s~storagelocation,
             s~product
        FROM zpp_i_batch_stock_vh AS s
        INNER JOIN @lt_material AS i
          ON i~table_line = s~product
        INTO TABLE @DATA(lt_stock).

    ENDIF.

    " Kalem kontrolleri
    LOOP AT lt_item INTO DATA(ls_check).

      DATA(lv_comp_mat)    = |{ ls_check-componentmaterial ALPHA = OUT }|.
      DATA(lv_comp_mat_in) = |{ ls_check-componentmaterial ALPHA = IN WIDTH = 18 }|.

      IF ls_check-componentmaterial IS INITIAL.

        APPEND VALUE #( %tky = ls_check-%tky ) TO failed-_item.

        APPEND VALUE #(
          %tky = ls_check-%tky
          %msg = new_message(
            id       = zcl_pp_conf=>mc_mess_id
            number   = '003'
            severity = if_abap_behv_message=>severity-error
          )
        ) TO reported-_item.

        lv_error_flag = abap_true.

      ENDIF.

      IF ls_check-storagelocation IS INITIAL.

        APPEND VALUE #( %tky = ls_check-%tky ) TO failed-_item.

        APPEND VALUE #(
          %tky = ls_check-%tky
          %msg = new_message(
            id       = zcl_pp_conf=>mc_mess_id
            number   = '013'
            severity = if_abap_behv_message=>severity-error
            v1       = lv_comp_mat
          )
        ) TO reported-_item.

        lv_error_flag = abap_true.

      ENDIF.

      " Parti sadece parti yönetimli kalemlerde zorunlu
      IF ls_check-isbatchmngmntrequired = abap_true
      AND ls_check-batch IS INITIAL.

        APPEND VALUE #( %tky = ls_check-%tky ) TO failed-_item.

        APPEND VALUE #(
          %tky = ls_check-%tky
          %msg = new_message(
            id       = zcl_pp_conf=>mc_mess_id
            number   = '014'
            severity = if_abap_behv_message=>severity-error
            v1       = lv_comp_mat
          )
        ) TO reported-_item.

        lv_error_flag = abap_true.

      ENDIF.

      IF ls_check-quantity IS INITIAL.

        APPEND VALUE #( %tky = ls_check-%tky ) TO failed-_item.

        APPEND VALUE #(
          %tky = ls_check-%tky
          %msg = new_message(
            id       = zcl_pp_conf=>mc_mess_id
            number   = '015'
            severity = if_abap_behv_message=>severity-error
            v1       = lv_comp_mat
          )
        ) TO reported-_item.

        lv_error_flag = abap_true.

      ENDIF.

      " Stok kontrolü sadece parti yönetimli kalemlerde çalışır
      IF ls_check-isbatchmngmntrequired = abap_true
      AND ls_check-componentmaterial IS NOT INITIAL
      AND ls_check-storagelocation IS NOT INITIAL
      AND ls_check-batch IS NOT INITIAL
      AND NOT line_exists(
        lt_stock[
          batch           = ls_check-batch
          storagelocation = ls_check-storagelocation
          product         = lv_comp_mat_in
        ]
      ).

        APPEND VALUE #( %tky = ls_check-%tky ) TO failed-_item.

        APPEND VALUE #(
          %tky = ls_check-%tky
          %msg = new_message(
            id       = zcl_pp_conf=>mc_mess_id
            number   = '016'
            severity = if_abap_behv_message=>severity-error
            v1       = lv_comp_mat
            v2       = ls_check-storagelocation
            v3       = |{ ls_check-batch ALPHA = OUT }|
          )
        ) TO reported-_item.

        lv_error_flag = abap_true.

      ENDIF.

    ENDLOOP.

    IF lv_error_flag = abap_true.

      IF failed-_header IS INITIAL.
        APPEND VALUE #( %tky = ls_header-%tky ) TO failed-_header.
      ENDIF.

      RETURN.

    ENDIF.

    """"""""""""""""""""""" BO BAŞLIK KONTROLLERİ """""""""""""""""""""""

    DATA(lv_material) = CONV matnr( |{ ls_header-material ALPHA = IN WIDTH = 18 }| ).
    DATA(lv_conftext) = |{ ls_header-shiftcode+1(1) }{ ls_header-groupcode }|.

    GET TIME STAMP FIELD lv_timestamp.

    TRY.

        CONVERT TIME STAMP lv_timestamp
          TIME ZONE cl_abap_context_info=>get_user_time_zone( )
          INTO DATE DATA(lv_date).

      CATCH cx_abap_context_info_error.

        APPEND VALUE #( %tky = <ls_key>-%tky ) TO failed-_header.

        APPEND VALUE #(
          %tky = <ls_key>-%tky
          %msg = new_message(
            id       = zcl_pp_conf=>mc_mess_id
            number   = '017'
            severity = if_abap_behv_message=>severity-error
          )
        ) TO reported-_header.

        RETURN.

    ENDTRY.

    " UOM Conversion
    SELECT SINGLE unitofmeasureisocode
      FROM i_unitofmeasure
      WHERE unitofmeasure = @ls_header-baseunit
      INTO @DATA(lv_uom).

    IF sy-subrc <> 0.

      APPEND VALUE #( %tky = <ls_key>-%tky ) TO failed-_header.

      APPEND VALUE #(
        %tky = <ls_key>-%tky
        %msg = new_message(
          id       = zcl_pp_conf=>mc_mess_id
          number   = '007'
          severity = if_abap_behv_message=>severity-error
          v1       = ls_header-material
          v2       = ls_header-baseunit
        )
      ) TO reported-_header.

      RETURN.

    ENDIF.

    " Production Version & BOM Variant
    DATA(ls_prodver) = zcl_pp_conf=>get_prod_version(
      iv_material = lv_material
      iv_plant    = zcl_pp_conf=>mc_plant
    ).

    IF ls_prodver-productionversion IS INITIAL
    OR ls_prodver-billofmaterialvariant IS INITIAL.

      APPEND VALUE #( %tky = <ls_key>-%tky ) TO failed-_header.

      APPEND VALUE #(
        %tky = <ls_key>-%tky
        %msg = new_message(
          id       = zcl_pp_conf=>mc_mess_id
          number   = '004'
          severity = if_abap_behv_message=>severity-error
          v1       = ls_header-material
        )
      ) TO reported-_header.

      RETURN.

    ENDIF.

    " Production Quantity
    IF ls_header-productiontype = zcl_pp_conf=>mc_ut_ym_borek
    AND ls_header-multiplier IS NOT INITIAL.
      ls_header-productionquantity = ls_header-productionquantity * ls_header-multiplier.
    ENDIF.

    """"""""""""""""""""""" BO Create Confirmation """""""""""""""""""""""

    MODIFY ENTITIES OF i_repetitivemfgconfirmationtp PRIVILEGED
      ENTITY repetitivemfgconfirmation
        CREATE SET FIELDS WITH VALUE #(
          (
            %cid                          = 'CONF_1'
            repetitivemfgconfscenario     = '01'
            rptvmfgconfprocessingtype     = 'B'
            confirmationentryquantity     = ls_header-productionquantity
            confirmationunitisocode       = lv_uom
            productionplant               = zcl_pp_conf=>mc_plant
            receivingbatch                = ls_header-productionbatch
            postingdate                   = lv_date
            documentdate                  = lv_date
            product                       = lv_material
            productionversion             = ls_prodver-productionversion
            repetitivemfgconfirmationtext = lv_conftext
          )
        )

      ENTITY repetitivemfgconfirmation
        CREATE BY \_rptvmfgconfmatldocitemtp
        SET FIELDS WITH VALUE #(
          (
            %cid_ref = 'CONF_1'
            %target = VALUE #(
              FOR ls_item IN lt_item INDEX INTO lv_index
              (
                %cid                = |GM_{ lv_index }|
                material            = CONV matnr( |{ ls_item-componentmaterial ALPHA = IN WIDTH = 18 }| )
                plant               = ls_header-plant
                storagelocation     = ls_item-storagelocation
                goodsmovementtype   = '261'
                entryunitsapcode    = ls_item-unit
                quantityinentryunit = ls_item-quantity
                batch               = COND #(
                                        WHEN ls_item-isbatchmngmntrequired = abap_true
                                        THEN ls_item-batch
                                        ELSE ''
                                      )
              )
            )
          )
        )
      MAPPED DATA(mapped_conf)
      FAILED DATA(failed_conf)
      REPORTED DATA(reported_conf).

    DATA(ls_mapped_conf) = VALUE #( mapped_conf-repetitivemfgconfirmation[ 1 ] OPTIONAL ).

    """"""""""""""""""""""""" DATA LOG """""""""""""""""""""""""

    lcl_buffer=>gs_conf_log = VALUE #(
      confuuid           = ls_header-confuuid
      shiftcode          = ls_header-shiftcode
      groupcode          = ls_header-groupcode
      material           = lv_material
      productionquantity = ls_header-productionquantity
      baseunit           = lv_uom
      productionbatch    = ls_header-productionbatch
      productionversion  = ls_prodver-productionversion
      plant              = ls_header-plant
    ).

    IF failed_conf IS NOT INITIAL.

      APPEND VALUE #( %tky = <ls_key>-%tky ) TO failed-_header.

      LOOP AT reported_conf-repetitivemfgconfirmation ASSIGNING FIELD-SYMBOL(<ls_rep_conf>)
        WHERE %msg IS BOUND.

        APPEND VALUE #( %tky = <ls_key>-%tky %msg = <ls_rep_conf>-%msg ) TO reported-_header.

        APPEND INITIAL LINE TO lcl_buffer=>gs_conf_log-item ASSIGNING FIELD-SYMBOL(<lfs_log_i>).
        <lfs_log_i>-status       = if_abap_behv_message=>severity-error.
        <lfs_log_i>-message_text = <ls_rep_conf>-%msg->if_message~get_text( ).

      ENDLOOP.

      LOOP AT reported_conf-rptvmfgconfmatldocitem ASSIGNING FIELD-SYMBOL(<ls_rep_item>)
        WHERE %msg IS BOUND.

        APPEND VALUE #( %tky = <ls_key>-%tky %msg = <ls_rep_item>-%msg ) TO reported-_header.

        APPEND INITIAL LINE TO lcl_buffer=>gs_conf_log-item ASSIGNING <lfs_log_i>.
        <lfs_log_i>-status       = if_abap_behv_message=>severity-error.
        <lfs_log_i>-message_text = <ls_rep_item>-%msg->if_message~get_text( ).

      ENDLOOP.

      IF reported-_header IS INITIAL.

        APPEND VALUE #(
          %tky = <ls_key>-%tky
          %msg = new_message(
            id       = zcl_pp_conf=>mc_mess_id
            number   = '006'
            severity = if_abap_behv_message=>severity-error
          )
        ) TO reported-_header.

        APPEND INITIAL LINE TO lcl_buffer=>gs_conf_log-item ASSIGNING <lfs_log_i>.
        <lfs_log_i>-status = if_abap_behv_message=>severity-error.

        MESSAGE ID zcl_pp_conf=>mc_mess_id TYPE 'E' NUMBER '006' INTO lv_mess.
        <lfs_log_i>-message_text = lv_mess.

      ENDIF.

      RETURN.

    ELSE.

      " Teyit Belgesi için PID loglanır
      IF ls_mapped_conf-%pid IS NOT INITIAL.

        lcl_buffer=>gs_conf_log-pid = ls_mapped_conf-%pid.

        APPEND VALUE #(
          %tky = <ls_key>-%tky
          %msg = new_message(
            id       = zcl_pp_conf=>mc_mess_id
            number   = '008'
            severity = if_abap_behv_message=>severity-success
          )
        ) TO reported-_header.

      ENDIF.

      LOOP AT reported_conf-repetitivemfgconfirmation ASSIGNING FIELD-SYMBOL(<ls_rep_success>)
        WHERE %msg IS BOUND.

        APPEND VALUE #( %tky = ls_header-%tky %msg = <ls_rep_success>-%msg ) TO reported-_header.

      ENDLOOP.

    ENDIF.

    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _header
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #(
      FOR ls_result IN lt_result
      (
        %tky   = ls_result-%tky
        %param = ls_result
      )
    ).

  ENDMETHOD.

  METHOD get_instance_authorizations.

    result = VALUE #(
      FOR key IN keys
      (
        %tky    = key-%tky
        %update = if_abap_behv=>auth-allowed
        %delete = if_abap_behv=>auth-allowed
      )
    ).

  ENDMETHOD.




*  METHOD get_instance_features.
*
*    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
*      ENTITY _header
*        FIELDS (
*          confuuid
*          shiftcode
*          material
*          productiontype
*          closingshift
*          confdoc
*        )
*        WITH CORRESPONDING #( keys )
*      RESULT DATA(lt_header).
*
*    LOOP AT lt_header ASSIGNING FIELD-SYMBOL(<ls_header>).
*
*      DATA(lv_is_confirmed) = xsdbool( <ls_header>-confdoc IS NOT INITIAL ).
*
*      DATA(lv_change_control) = COND #(
*        WHEN lv_is_confirmed = abap_true THEN if_abap_behv=>fc-o-disabled
*        ELSE if_abap_behv=>fc-o-enabled
*      ).
*
*      DATA(lv_has_required_draft_data) = xsdbool(
*           lv_is_confirmed = abap_false
*       AND <ls_header>-%is_draft = if_abap_behv=>mk-on
*       AND <ls_header>-shiftcode IS NOT INITIAL
*       AND <ls_header>-material  IS NOT INITIAL
*      ).
*
*      DATA(lv_draft_action_control) = COND #(
*        WHEN lv_has_required_draft_data = abap_true THEN if_abap_behv=>fc-o-enabled
*        ELSE if_abap_behv=>fc-o-disabled
*      ).
*
*      DATA(lv_has_required_active_data) = xsdbool(
*           lv_is_confirmed = abap_false
*       AND <ls_header>-%is_draft = if_abap_behv=>mk-off
*       AND <ls_header>-shiftcode IS NOT INITIAL
*       AND <ls_header>-material  IS NOT INITIAL
*      ).
*
*      DATA(lv_confirmation_control) = COND #(
*        WHEN lv_has_required_active_data = abap_true THEN if_abap_behv=>fc-o-enabled
*        ELSE if_abap_behv=>fc-o-disabled
*      ).
*
*      " Iskarta Malzeme Kullan action kontrolü
*      DATA(lv_use_scrap_material_control) = COND #(
*        WHEN lv_is_confirmed = abap_true THEN if_abap_behv=>fc-o-disabled
*
*        WHEN <ls_header>-%is_draft = if_abap_behv=>mk-on
*         AND <ls_header>-shiftcode IS NOT INITIAL
*         AND <ls_header>-material IS NOT INITIAL
*         AND <ls_header>-closingshift <> abap_true
*         AND (
*              <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_borek
*           OR <ls_header>-productiontype = zcl_pp_conf=>mc_ut_mamul_ee_lahmacun
*           OR <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_ee_lahmacun
*         )
*        THEN if_abap_behv=>fc-o-enabled
*
*        ELSE if_abap_behv=>fc-o-disabled
*      ).
*
*      APPEND VALUE #(
*        %tky = <ls_header>-%tky
*
*        " Standart update/delete
*        %update = lv_change_control
*        %delete = lv_change_control
*
*        " Object Page üstündeki standart Düzenle butonu
*        %action-edit = lv_change_control
*
*        " Draft/edit mod actionları
*        %action-downtimereason   = lv_draft_action_control
*        %action-getprodquan      = lv_draft_action_control
*        %action-definebatch      = lv_draft_action_control
*        %action-getmatcomponents = lv_draft_action_control
*        %action-usescrapmaterial = lv_use_scrap_material_control
*
*        " Active/display mod action
*        %action-confirmation     = lv_confirmation_control
*      ) TO result.
*
*    ENDLOOP.
*
*  ENDMETHOD.


  METHOD get_instance_features.

    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _header
        FIELDS (
          confuuid
          shiftcode
          material
          productiontype
          closingshift
          confdoc
        )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_header).

    LOOP AT lt_header ASSIGNING FIELD-SYMBOL(<ls_header>).

      DATA(lv_is_confirmed) = xsdbool( <ls_header>-confdoc IS NOT INITIAL ).

      DATA(lv_change_control) = COND #(
        WHEN lv_is_confirmed = abap_true THEN if_abap_behv=>fc-o-disabled
        ELSE if_abap_behv=>fc-o-enabled
      ).

      DATA(lv_has_required_draft_data) = xsdbool(
           lv_is_confirmed = abap_false
       AND <ls_header>-%is_draft = if_abap_behv=>mk-on
       AND <ls_header>-shiftcode IS NOT INITIAL
       AND <ls_header>-material  IS NOT INITIAL
      ).

      DATA(lv_draft_action_control) = COND #(
        WHEN lv_has_required_draft_data = abap_true THEN if_abap_behv=>fc-o-enabled
        ELSE if_abap_behv=>fc-o-disabled
      ).

      DATA(lv_has_required_active_data) = xsdbool(
           lv_is_confirmed = abap_false
       AND <ls_header>-%is_draft = if_abap_behv=>mk-off
       AND <ls_header>-shiftcode IS NOT INITIAL
       AND <ls_header>-material  IS NOT INITIAL
      ).

      DATA(lv_confirmation_control) = COND #(
        WHEN lv_has_required_active_data = abap_true THEN if_abap_behv=>fc-o-enabled
        ELSE if_abap_behv=>fc-o-disabled
      ).

      " Üretim Miktarı Getir action kontrolü
      DATA(lv_getprodquan_control) = COND #(
        WHEN lv_has_required_draft_data = abap_true
         AND (
              <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_kurabiye_simit
           OR <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_ee_lahmacun
         )
        THEN if_abap_behv=>fc-o-enabled
        ELSE if_abap_behv=>fc-o-disabled
      ).

      " Iskarta Malzeme Kullan action kontrolü
      DATA(lv_use_scrap_material_control) = COND #(
        WHEN lv_is_confirmed = abap_true THEN if_abap_behv=>fc-o-disabled

        WHEN <ls_header>-%is_draft = if_abap_behv=>mk-on
         AND <ls_header>-shiftcode IS NOT INITIAL
         AND <ls_header>-material IS NOT INITIAL
         AND <ls_header>-closingshift <> abap_true
         AND (
              <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_borek
           OR <ls_header>-productiontype = zcl_pp_conf=>mc_ut_mamul_ee_lahmacun
           OR <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_ee_lahmacun
         )
        THEN if_abap_behv=>fc-o-enabled

        ELSE if_abap_behv=>fc-o-disabled
      ).

      APPEND VALUE #(
        %tky = <ls_header>-%tky

        " Standart update/delete
        %update = lv_change_control
        %delete = lv_change_control

        " Object Page üstündeki standart Düzenle butonu
        %action-edit = lv_change_control

        " Draft/edit mod actionları
        %action-downtimereason   = lv_draft_action_control
        %action-definebatch      = lv_draft_action_control
        %action-getmatcomponents = lv_draft_action_control

        " Üretim türüne bağlı actionlar
        %action-getprodquan      = lv_getprodquan_control
        %action-usescrapmaterial = lv_use_scrap_material_control

        " Active/display mod action
        %action-confirmation     = lv_confirmation_control
      ) TO result.

    ENDLOOP.

  ENDMETHOD.


  METHOD fillmaterialdata.

    DATA lt_update      TYPE TABLE FOR UPDATE zpp_i_conf_h.
    DATA lt_delete_item TYPE TABLE FOR DELETE zpp_i_conf_i.
    DATA lt_create      TYPE TABLE FOR CREATE zpp_i_conf_h\_items.
    DATA lv_cid_no      TYPE i.

    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _header
        FIELDS (
          material
          productionquantity
        )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_header).

    READ TABLE lt_header ASSIGNING FIELD-SYMBOL(<ls_header>) INDEX 1.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    READ TABLE keys ASSIGNING FIELD-SYMBOL(<ls_key>)
      WITH KEY %tky = <ls_header>-%tky.

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Malzeme boşaltıldıysa header alanlarını ve itemları temizle
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    IF <ls_header>-material IS INITIAL.

      READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
        ENTITY _header BY \_items
          ALL FIELDS
          WITH CORRESPONDING #( keys )
        RESULT DATA(lt_existing_item_clear).

      lt_delete_item = VALUE #(
        FOR ls_item IN lt_existing_item_clear
        (
          %tky      = ls_item-%tky
          %is_draft = ls_item-%is_draft
        )
      ).

      IF lt_delete_item IS NOT INITIAL.

        MODIFY ENTITIES OF zpp_i_conf_h IN LOCAL MODE
          ENTITY _item
            DELETE FROM lt_delete_item
          MAPPED DATA(mapped_delete_clear)
          FAILED DATA(failed_delete_clear)
          REPORTED DATA(reported_delete_clear).

      ENDIF.

      APPEND INITIAL LINE TO lt_update ASSIGNING FIELD-SYMBOL(<ls_clear>).

      <ls_clear>-%tky = <ls_header>-%tky.

      CLEAR:
        <ls_clear>-materialdescription,
        <ls_clear>-baseunit,
        <ls_clear>-productiontype,
        <ls_clear>-productionversion,
        <ls_clear>-chargequantity,
        <ls_clear>-productionquantity,
        <ls_clear>-multiplier,
        <ls_clear>-closingshift.

      <ls_clear>-hideclosingshift   = abap_false.
      <ls_clear>-hidechargequantity = abap_false.
      <ls_clear>-hidemultiplier     = abap_false.

      MODIFY ENTITIES OF zpp_i_conf_h IN LOCAL MODE
        ENTITY _header
          UPDATE FIELDS (
            materialdescription
            baseunit
            productiontype
            productionversion
            chargequantity
            productionquantity
            multiplier
            closingshift
            hideclosingshift
            hidechargequantity
            hidemultiplier
          )
          WITH lt_update
        REPORTED DATA(lt_reported_clear).

      RETURN.

    ENDIF.

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Malzeme doluysa ana verileri oku
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    DATA(lv_material)    = CONV matnr( |{ <ls_header>-material }| ).
    DATA(lv_material_in) = CONV matnr( |{ <ls_header>-material ALPHA = IN WIDTH = 18 }| ).

    SELECT SINGLE product,
                  productname,
                  baseunit
      FROM zi_product_vh
      WHERE product = @lv_material
      INTO @DATA(ls_product).
    IF sy-subrc <> 0.
      IF <ls_key> IS ASSIGNED.
        APPEND VALUE #(
          %tky = <ls_key>-%tky
          %msg = new_message(
            id       = zcl_pp_conf=>mc_mess_id
            number   = '010'
            severity = if_abap_behv_message=>severity-error
            v1       = lv_material
          )
        ) TO reported-_header.
      ENDIF.
      RETURN.
    ENDIF.

    DATA(ls_prod_type) = zcl_pp_conf=>get_prod_type( iv_material = lv_material ).
    IF ls_prod_type IS INITIAL.
*      IF <ls_key> IS ASSIGNED.
*        APPEND VALUE #(
*          %tky = <ls_key>-%tky
*          %msg = new_message(
*            id       = zcl_pp_conf=>mc_mess_id
*            number   = '009'
*            severity = if_abap_behv_message=>severity-error
*            v1       = lv_material
*          )
*        ) TO reported-_header.
*      ENDIF.
*      RETURN.
    ENDIF.

    DATA(ls_prodver) = zcl_pp_conf=>get_prod_version( iv_material = lv_material iv_plant = zcl_pp_conf=>mc_plant ).

    IF ls_prod_type-uretimturu = zcl_pp_conf=>mc_ut_sarjli.
      DATA(ls_charge) = zcl_pp_conf=>get_charge_quan( iv_material = lv_material ).
    ENDIF.


    """""""""""""""""""""""""""""" Header alanlarını güncelle """"""""""""""""""""""""""""""""

    APPEND INITIAL LINE TO lt_update ASSIGNING FIELD-SYMBOL(<ls_update>).

    <ls_update>-%tky = <ls_header>-%tky.

    <ls_update>-materialdescription = ls_product-productname.
    <ls_update>-baseunit            = ls_product-baseunit.
    <ls_update>-productiontype      = ls_prod_type-uretimturu.
    <ls_update>-plant               = zcl_pp_conf=>mc_plant.
    <ls_update>-productionversion   = ls_prodver-productionversion.
    <ls_update>-productionquantity  = <ls_header>-productionquantity.

*    <ls_update>-chargequantity = 1.


    """"""""""""""""""""""""""" Ekran kapat Aç """""""""""""""""""""""""""""""""""""""
    <ls_update>-hideclosingshift = COND abap_boolean(
      WHEN ls_prod_type-uretimturu = zcl_pp_conf=>mc_ut_mamul_ee_lahmacun
        OR ls_prod_type-uretimturu = zcl_pp_conf=>mc_ut_ym_ee_lahmacun
        OR ls_prod_type-uretimturu = zcl_pp_conf=>mc_ut_ym_borek
      THEN abap_false
      ELSE abap_true
    ).

    " Üretim türü uygun değilse Son Vardiya tikini de kapat
    <ls_update>-closingshift = COND abap_boolean(
      WHEN <ls_update>-hideclosingshift = abap_true
      THEN abap_false
      ELSE <ls_header>-closingshift
    ).

    " Şarş Miktarı tabloda var ise alanı aç, yok ise kapat
    "
    IF ls_prod_type-uretimturu = zcl_pp_conf=>mc_ut_sarjli.
      IF ls_charge-sarjmiktari > 0.
        <ls_update>-hidechargequantity = abap_false.
      ELSE.
        APPEND VALUE #( %tky = <ls_key>-%tky %msg = new_message( id = zcl_pp_conf=>mc_mess_id number = '059'
        severity = if_abap_behv_message=>severity-error v1 = lv_material ) ) TO reported-_header. RETURN.
      ENDIF.
    ELSE.
      <ls_update>-hidechargequantity = abap_true.
      <ls_update>-chargequantity     = 0.
    ENDIF.

    " Çarpan Aç/kapa işlemi
    <ls_update>-hidemultiplier = COND abap_boolean(
      WHEN ls_prod_type-uretimturu = zcl_pp_conf=>mc_ut_ym_borek
      THEN abap_false
      ELSE abap_true
    ).
    "" Ekran kapat Aç Bitti -->


    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    """""""""""""""""""""" Başlık Güncelle """"""""""""""""
    MODIFY ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _header
        UPDATE FIELDS (
          materialdescription
          baseunit
          productiontype
          plant
          productionversion
          hideclosingshift
          closingshift
          hidechargequantity
          hidemultiplier
          chargequantity
        )
        WITH lt_update
      REPORTED DATA(lt_reported).

    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    """""""""""""""""""""" Bileşenleri Temizle """"""""""""""""
    CLEAR:
      lt_delete_item,
      lt_create,
      lv_cid_no.

    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _header BY \_items
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_existing_item).

    lt_delete_item = VALUE #(
      FOR ls_item IN lt_existing_item
      (
        %tky      = ls_item-%tky
        %is_draft = ls_item-%is_draft
      )
    ).

    IF lt_delete_item IS NOT INITIAL.
      MODIFY ENTITIES OF zpp_i_conf_h IN LOCAL MODE
        ENTITY _item
          DELETE FROM lt_delete_item
        MAPPED DATA(mapped_delete)
        FAILED DATA(failed_delete)
        REPORTED DATA(reported_delete).
    ENDIF.

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Otomatik BOM patlatma kontrolü
    " Sadece otomatik BOM ym_kurabiye_simit değil ve üretim miktarı girildiyse
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    IF xsdbool( ls_prod_type-uretimturu <> zcl_pp_conf=>mc_ut_ym_kurabiye_simit  ) = abap_true
     AND <ls_header>-productionquantity IS NOT INITIAL.

      DATA(lv_quantity) = CONV menge_d( <ls_header>-productionquantity ).

      DATA(lt_bom_result) = zcl_pp_conf=>explode_bom(
        iv_material = lv_material_in
        iv_quantity = lv_quantity
      ).

      IF lt_bom_result IS NOT INITIAL.


        SELECT c~mamul,
           c~yarimamul,
           c~arabakg  FROM zpp_t_conf_004 AS c
          INNER JOIN @lt_bom_result AS l
            ON  c~mamul     = l~material
            AND c~yarimamul = l~component
            AND l~bom_item_cat = @zcl_pp_conf=>mc_bomitemcat_z
          INTO TABLE @DATA(lt_conf_004).


        APPEND VALUE #(
          %tky      = <ls_header>-%tky
          %is_draft = <ls_header>-%is_draft
        ) TO lt_create ASSIGNING FIELD-SYMBOL(<ls_create>).

        LOOP AT lt_bom_result ASSIGNING FIELD-SYMBOL(<ls_bom>).

          IF <ls_header>-productiontype <> zcl_pp_conf=>mc_ut_mamul_kurabiye AND
              <ls_bom>-bom_item_cat = zcl_pp_conf=>mc_bomitemcat_z.
            DATA(ls_conf_004) = VALUE #( lt_conf_004[ mamul  = <ls_bom>-material yarimamul = <ls_bom>-component ] OPTIONAL ).
            IF ls_conf_004 IS INITIAL.
              APPEND VALUE #(  %tky = <ls_header>-%tky
              %msg = new_message( id = zcl_pp_conf=>mc_mess_id  number = '031' severity = if_abap_behv_message=>severity-error v1 = <ls_bom>-component ) ) TO reported-_header.
            ENDIF.
          ENDIF.


          lv_cid_no += 1.

          APPEND VALUE #(
            %cid      = |ITEM_{ lv_cid_no }|
            %is_draft = <ls_header>-%is_draft

            itemno               = <ls_bom>-bom_item_number
            componentmaterial    = |{ <ls_bom>-component ALPHA = OUT }|
            componentdescription = <ls_bom>-component_text
            storagelocation      = <ls_bom>-storage_location
            quantity             = COND #( WHEN <ls_bom>-bom_item_cat = zcl_pp_conf=>mc_bomitemcat_z THEN 0 ELSE <ls_bom>-quantity )
            unit                 = <ls_bom>-unit
            batch                = ''
            carcount             = 0
            actualstockquantity  = 0
            bomitemcat           = <ls_bom>-bom_item_cat
            isbatchmngmntrequired = <ls_bom>-isbatchmanagementrequired
          ) TO <ls_create>-%target.

        ENDLOOP.

        CHECK reported-_header IS INITIAL.
        MODIFY ENTITIES OF zpp_i_conf_h IN LOCAL MODE
          ENTITY _header
            CREATE BY \_items
            FIELDS (
              itemno
              componentmaterial
              componentdescription
              storagelocation
              batch
              quantity
              unit
              carcount
              actualstockquantity
              bomitemcat
              isbatchmngmntrequired
            )
            WITH lt_create
          MAPPED DATA(mapped_create)
          FAILED DATA(failed_create)
          REPORTED DATA(reported_create).

      ENDIF.

    ENDIF.



  ENDMETHOD.


  METHOD setproductionbatch.

    DATA lt_update TYPE TABLE FOR UPDATE zpp_i_conf_h.

    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _header
        FIELDS ( shiftcode )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_header).

    DELETE lt_header WHERE shiftcode IS INITIAL.

    CHECK lt_header IS NOT INITIAL.

    DATA(lv_date) = cl_abap_context_info=>get_system_date( ).

    DATA(lv_date_text) = |{ lv_date+6(2) }{ lv_date+4(2) }{ lv_date+2(2) }|.

    lt_update = VALUE #(
      FOR ls_header IN lt_header
      (
        %tky            = ls_header-%tky
        productionbatch = |{ lv_date_text }-{ ls_header-shiftcode+1(1) }|
      )
    ).

    MODIFY ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _header
        UPDATE FIELDS ( productionbatch )
        WITH lt_update
      REPORTED DATA(lt_reported).


  ENDMETHOD.


  METHOD downtimereason.

    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _header
        FIELDS ( confuuid shiftcode groupcode material )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_header).
    IF lt_header IS INITIAL.
      RETURN.
    ENDIF.

    " Duruş tarih/saati Türkiye (kullanıcı logon) saat dilimine göre — UTC değil.
    DATA lv_date TYPE d.
    DATA lv_time TYPE t.
    CONVERT UTCLONG utclong_current( )
      INTO DATE lv_date TIME lv_time
      TIME ZONE sy-zonlo.

    LOOP AT lt_header ASSIGNING FIELD-SYMBOL(<ls_header>).

      READ TABLE keys ASSIGNING FIELD-SYMBOL(<ls_key>)
        WITH KEY %tky = <ls_header>-%tky.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.


      IF <ls_key>-%param-workcenter IS INITIAL
      OR <ls_key>-%param-downtimecode IS INITIAL
      OR <ls_key>-%param-downtimeduration IS INITIAL.

        APPEND VALUE #(
          %tky = <ls_header>-%tky
        ) TO failed-_header.

        APPEND VALUE #(
          %tky = <ls_header>-%tky
          %msg = new_message(
            id       = zcl_pp_conf=>mc_mess_id
            number   = '019'
            severity = if_abap_behv_message=>severity-error
          )
        ) TO reported-_header.

        CONTINUE.

      ENDIF.

      DATA(lv_material_internal) = CONV matnr( |{ <ls_header>-material ALPHA = IN WIDTH = 18 }| ).

      APPEND VALUE #(
        shiftcode         = <ls_header>-shiftcode
        groupcode         = <ls_header>-groupcode
        workcenter        = <ls_key>-%param-workcenter
        material          = lv_material_internal
        downtime_date     = lv_date
        downtime_time     = lv_time
        shift             = |{ <ls_header>-shiftcode+1(1) }{ <ls_header>-groupcode }|
        downtime_code     = <ls_key>-%param-downtimecode
        downtime_duration = <ls_key>-%param-downtimeduration
        downtime_baseunit = zcl_pp_conf=>mc_dak
      ) TO lcl_buffer=>gt_dwntm.

    ENDLOOP.


    CHECK failed-_header IS INITIAL.

    APPEND VALUE #(
          %tky = <ls_header>-%tky
          %msg = new_message(
            id       = zcl_pp_conf=>mc_mess_id
            number   = '020'
            severity = if_abap_behv_message=>severity-success
          )
        ) TO reported-_header.

    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _header
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #(
      FOR ls_result IN lt_result
      (
        %tky   = ls_result-%tky
        %param = ls_result
      )
    ).



  ENDMETHOD.

*  METHOD getprodquan.
*
*    DATA: lv_total_kg      TYPE menge_d,
*          lv_item_qty_kg   TYPE menge_d,
*          lv_firin_firesi  TYPE zpp_i_conf_h-productionquantity,
*          lv_prod_quantity TYPE zpp_i_conf_h-productionquantity,
*          lv_has_error     TYPE abap_boolean.
*
*    DATA lt_kepek_material TYPE SORTED TABLE OF matnr WITH UNIQUE KEY table_line.
*
*    " Başlık ve kalemler okunur
*    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
*      ENTITY _header
*        FIELDS (
*          confuuid
*          material
*          productiontype
*          productionquantity
*          baseunit
*        )
*        WITH CORRESPONDING #( keys )
*        RESULT DATA(lt_header)
*
*      ENTITY _header BY \_items
*        FIELDS (
*          itemuuid
*          confuuid
*          componentmaterial
*          quantity
*          unit
*          bomitemcat
*        )
*        WITH CORRESPONDING #( keys )
*        RESULT DATA(lt_item).
*
*    READ TABLE lt_header ASSIGNING FIELD-SYMBOL(<ls_header>) INDEX 1.
*    IF sy-subrc <> 0.
*      RETURN.
*    ENDIF.
*
*    " Üretim türü kontrolü
*    IF <ls_header>-productiontype <> zcl_pp_conf=>mc_ut_ym_kurabiye_simit
*   AND <ls_header>-productiontype <> zcl_pp_conf=>mc_ut_ym_ee_lahmacun.
*
*      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
*      APPEND VALUE #( %tky = <ls_header>-%tky %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
*      text = |Üretim Miktarı Getir işlemi bu üretim türü için kullanılamaz.| ) ) TO reported-_header.
*      RETURN.
*
*    ENDIF.
*
*    IF lt_item IS INITIAL.
*      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
*      APPEND VALUE #( %tky = <ls_header>-%tky %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
*      text = |Kalem bulunamadı.| ) ) TO reported-_header.
*      RETURN.
*    ENDIF.
*
*    " YM_EE_LAHMACUN için kepek malzemeleri okunur
*    IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_ee_lahmacun.
*
*      SELECT malzeme
*        FROM zpp_t_conf_014
*        INTO TABLE @DATA(lt_t014).
*
*      LOOP AT lt_t014 ASSIGNING FIELD-SYMBOL(<ls_t014>).
*        INSERT CONV matnr( |{ <ls_t014>-malzeme ALPHA = IN WIDTH = 18 }| ) INTO TABLE lt_kepek_material.
*      ENDLOOP.
*
*    ENDIF.
*
*    " Kalemler üretim türüne göre hesaplanır
*    LOOP AT lt_item ASSIGNING FIELD-SYMBOL(<ls_item>).
*
*      DATA(lv_component) = CONV matnr( |{ <ls_item>-componentmaterial ALPHA = IN WIDTH = 18 }| ).
*
*      " YM_KURABIYE_SIMIT: sadece Z kalemler
*      IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_kurabiye_simit
*     AND <ls_item>-bomitemcat <> zcl_pp_conf=>mc_bomitemcat_z.
*        CONTINUE.
*      ENDIF.
*
*      " YM_EE_LAHMACUN: Z kalemler veya kepek malzemeleri
*      IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_ee_lahmacun
*     AND <ls_item>-bomitemcat <> zcl_pp_conf=>mc_bomitemcat_z
*     AND NOT line_exists( lt_kepek_material[ table_line = lv_component ] ).
*        CONTINUE.
*      ENDIF.
*
*      " YM_EE_LAHMACUN için ilgili kalem miktarı 0 olamaz
*      IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_ee_lahmacun
*     AND <ls_item>-quantity IS INITIAL.
*
*        APPEND VALUE #( %tky = <ls_item>-%tky ) TO failed-_item.
*        APPEND VALUE #( %tky = <ls_item>-%tky %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
*         text = |{ <ls_item>-componentmaterial } için miktar 0 olamaz. Miktar kullanıcı tarafından girilmelidir.| ) ) TO reported-_item.
*        lv_has_error = abap_true.
*        CONTINUE.
*
*      ENDIF.
*
*      " YM_KURABIYE_SIMIT için 0 miktarlı Z kalemi hesaplamaya alma
*      IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_kurabiye_simit
*     AND <ls_item>-quantity IS INITIAL.
*        CONTINUE.
*      ENDIF.
*
*      CLEAR lv_item_qty_kg.
*
*      IF <ls_item>-unit = 'KG'.
*        lv_item_qty_kg = <ls_item>-quantity.
*      ELSEIF <ls_item>-unit = 'G'.
*        lv_item_qty_kg = <ls_item>-quantity / 1000.
*      ELSE.
*
*        " KG olmayan birimler KG'ye çevrilir
*        zcl_pp_conf=>convert_material_quantity(
*          EXPORTING
*            iv_product    = lv_component
*            iv_source_qty = <ls_item>-quantity
*            iv_source_uom = CONV msehi( <ls_item>-unit )
*            iv_target_uom = CONV msehi( 'KG' )
*          IMPORTING
*            ev_target_qty = lv_item_qty_kg
*        ).
*
*        IF lv_item_qty_kg IS INITIAL.
*          APPEND VALUE #( %tky = <ls_item>-%tky ) TO failed-_item.
*          APPEND VALUE #( %tky = <ls_item>-%tky %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
*          text = |{ <ls_item>-componentmaterial } malzemesi için KG dönüşümü yapılamadı.| ) ) TO reported-_item.
*          lv_has_error = abap_true.
*          CONTINUE.
*        ENDIF.
*
*      ENDIF.
*
*      lv_total_kg = lv_total_kg + lv_item_qty_kg.
*
*    ENDLOOP.
*
*    IF lv_has_error = abap_true.
*      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
*      RETURN.
*    ENDIF.
*
*    IF lv_total_kg IS INITIAL.
*      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
*
*      IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_kurabiye_simit.
*        APPEND VALUE #( %tky = <ls_header>-%tky %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
*        text = |BomItemCat = Z olan kalemlerde KG toplamı bulunamadı.| ) ) TO reported-_header.
*      ELSE.
*        APPEND VALUE #( %tky = <ls_header>-%tky %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
*        text = |BomItemCat = Z veya kepek malzemesi olan kalemlerde KG toplamı bulunamadı.| ) ) TO reported-_header.
*      ENDIF.
*
*      RETURN.
*    ENDIF.
*
*    " YM_KURABIYE_SIMIT: Toplam KG * fırın firesi
*    IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_kurabiye_simit.
*
*      DATA(lv_header_material) = CONV matnr( |{ <ls_header>-material ALPHA = IN WIDTH = 18 }| ).
*
*      SELECT SINGLE firinfiresi
*        FROM zpp_t_conf_003
*        WHERE product = @lv_header_material
*        INTO @lv_firin_firesi.
*
*      IF sy-subrc <> 0 OR lv_firin_firesi IS INITIAL.
*        APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
*        APPEND VALUE #( %tky = <ls_header>-%tky %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
*        text = |Üretim malzemesi için fırın firesi bulunamadı.| ) ) TO reported-_header.
*        RETURN.
*      ENDIF.
*
*      lv_prod_quantity = lv_total_kg * lv_firin_firesi.
*
*    ENDIF.
*
*    " YM_EE_LAHMACUN: Toplam KG direkt üretim miktarı
*    IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_ee_lahmacun.
*      lv_prod_quantity = lv_total_kg.
*    ENDIF.
*
*    " Üretim miktarı başlığa yazılır
*    MODIFY ENTITIES OF zpp_i_conf_h IN LOCAL MODE
*      ENTITY _header
*        UPDATE FIELDS ( productionquantity )
*        WITH VALUE #(
*          (
*            %tky = <ls_header>-%tky
*            productionquantity = lv_prod_quantity
*          )
*        )
*      FAILED DATA(lt_failed_update)
*      REPORTED DATA(lt_reported_update).
*
*    IF lt_failed_update-_header IS NOT INITIAL.
*      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
*      APPEND VALUE #( %tky = <ls_header>-%tky %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
*      text = |Üretim miktarı güncellenemedi.| ) ) TO reported-_header.
*      RETURN.
*    ENDIF.
*
*    APPEND VALUE #( %tky = <ls_header>-%tky %msg = new_message_with_text( severity = if_abap_behv_message=>severity-success
*     text = |Üretim miktarı hesaplandı.| ) ) TO reported-_header.
*
*    " Güncel başlık sonucu döndürülür
*    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
*      ENTITY _header
*        ALL FIELDS
*        WITH CORRESPONDING #( keys )
*        RESULT DATA(lt_result).
*
*    result = VALUE #( FOR ls_result IN lt_result ( %tky = ls_result-%tky %param = ls_result ) ).
*
*  ENDMETHOD.


*  METHOD getprodquan.
*
*    DATA: lv_total_kg      TYPE menge_d,
*          lv_item_qty_kg   TYPE menge_d,
*          lv_firin_firesi  TYPE zpp_i_conf_h-productionquantity,
*          lv_prod_quantity TYPE zpp_i_conf_h-productionquantity,
*          lv_has_error     TYPE abap_boolean.
*
*    DATA lt_kepek_material TYPE SORTED TABLE OF matnr WITH UNIQUE KEY table_line.
*
*    " Başlık ve kalemler okunur
*    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
*      ENTITY _header
*        FIELDS (
*          confuuid
*          material
*          productiontype
*          productionquantity
*          baseunit
*        )
*        WITH CORRESPONDING #( keys )
*        RESULT DATA(lt_header)
*
*      ENTITY _header BY \_items
*        FIELDS (
*          itemuuid
*          confuuid
*          componentmaterial
*          quantity
*          unit
*          bomitemcat
*        )
*        WITH CORRESPONDING #( keys )
*        RESULT DATA(lt_item).
*
*    READ TABLE lt_header ASSIGNING FIELD-SYMBOL(<ls_header>) INDEX 1.
*    IF sy-subrc <> 0.
*      RETURN.
*    ENDIF.
*
*    " Üretim türü kontrolü
*    IF <ls_header>-productiontype <> zcl_pp_conf=>mc_ut_ym_kurabiye_simit
*   AND <ls_header>-productiontype <> zcl_pp_conf=>mc_ut_ym_ee_lahmacun.
*
*      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
*
*      APPEND VALUE #(
*        %tky = <ls_header>-%tky
*        %msg = new_message(
*          id       = zcl_pp_conf=>mc_mess_id
*          number   = '048'
*          severity = if_abap_behv_message=>severity-error
*        )
*      ) TO reported-_header.
*
*      RETURN.
*
*    ENDIF.
*
*    IF lt_item IS INITIAL.
*
*      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
*
*      APPEND VALUE #(
*        %tky = <ls_header>-%tky
*        %msg = new_message(
*          id       = zcl_pp_conf=>mc_mess_id
*          number   = '049'
*          severity = if_abap_behv_message=>severity-error
*        )
*      ) TO reported-_header.
*
*      RETURN.
*
*    ENDIF.
*
*    " YM_EE_LAHMACUN için kepek malzemeleri okunur
*    IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_ee_lahmacun.
*
*      SELECT malzeme
*        FROM zpp_t_conf_014
*        INTO TABLE @DATA(lt_t014).
*
*      LOOP AT lt_t014 ASSIGNING FIELD-SYMBOL(<ls_t014>).
*        INSERT CONV matnr( |{ <ls_t014>-malzeme ALPHA = IN WIDTH = 18 }| ) INTO TABLE lt_kepek_material.
*      ENDLOOP.
*
*    ENDIF.
*
*    " Kalemler üretim türüne göre hesaplanır
*    LOOP AT lt_item ASSIGNING FIELD-SYMBOL(<ls_item>).
*
*      DATA(lv_component) = CONV matnr( |{ <ls_item>-componentmaterial ALPHA = IN WIDTH = 18 }| ).
*
*      " YM_KURABIYE_SIMIT: sadece Z kalemler
*      IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_kurabiye_simit
*     AND <ls_item>-bomitemcat <> zcl_pp_conf=>mc_bomitemcat_z.
*        CONTINUE.
*      ENDIF.
*
*      " YM_EE_LAHMACUN: Z kalemler veya kepek malzemeleri
*      IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_ee_lahmacun
*     AND <ls_item>-bomitemcat <> zcl_pp_conf=>mc_bomitemcat_z
*     AND NOT line_exists( lt_kepek_material[ table_line = lv_component ] ).
*        CONTINUE.
*      ENDIF.
*
*      " YM_EE_LAHMACUN için ilgili kalem miktarı 0 olamaz
*      IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_ee_lahmacun
*     AND <ls_item>-quantity IS INITIAL.
*
*        APPEND VALUE #( %tky = <ls_item>-%tky ) TO failed-_item.
*
*        APPEND VALUE #(
*          %tky = <ls_item>-%tky
*          %msg = new_message(
*            id       = zcl_pp_conf=>mc_mess_id
*            number   = '050'
*            severity = if_abap_behv_message=>severity-error
*            v1       = |{ <ls_item>-componentmaterial ALPHA = OUT }|
*          )
*        ) TO reported-_item.
*
*        lv_has_error = abap_true.
*        CONTINUE.
*
*      ENDIF.
*
*      " YM_KURABIYE_SIMIT için 0 miktarlı Z kalemi hesaplamaya alma
*      IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_kurabiye_simit
*     AND <ls_item>-quantity IS INITIAL.
*        CONTINUE.
*      ENDIF.
*
*      CLEAR lv_item_qty_kg.
*
*      IF <ls_item>-unit = 'KG'.
*
*        lv_item_qty_kg = <ls_item>-quantity.
*
*      ELSEIF <ls_item>-unit = 'G'.
*
*        lv_item_qty_kg = <ls_item>-quantity / 1000.
*
*      ELSE.
*
*        " KG olmayan birimler KG'ye çevrilir
*        zcl_pp_conf=>convert_material_quantity(
*          EXPORTING
*            iv_product    = lv_component
*            iv_source_qty = <ls_item>-quantity
*            iv_source_uom = CONV msehi( <ls_item>-unit )
*            iv_target_uom = CONV msehi( 'KG' )
*          IMPORTING
*            ev_target_qty = lv_item_qty_kg
*        ).
*
*        IF lv_item_qty_kg IS INITIAL.
*
*          APPEND VALUE #( %tky = <ls_item>-%tky ) TO failed-_item.
*
*          APPEND VALUE #(
*            %tky = <ls_item>-%tky
*            %msg = new_message(
*              id       = zcl_pp_conf=>mc_mess_id
*              number   = '051'
*              severity = if_abap_behv_message=>severity-error
*              v1       = |{ <ls_item>-componentmaterial ALPHA = OUT }|
*            )
*          ) TO reported-_item.
*
*          lv_has_error = abap_true.
*          CONTINUE.
*
*        ENDIF.
*
*      ENDIF.
*
*      lv_total_kg = lv_total_kg + lv_item_qty_kg.
*
*    ENDLOOP.
*
*    IF lv_has_error = abap_true.
*      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
*      RETURN.
*    ENDIF.
*
*    IF lv_total_kg IS INITIAL.
*
*      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
*
*      IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_kurabiye_simit.
*
*        APPEND VALUE #(
*          %tky = <ls_header>-%tky
*          %msg = new_message(
*            id       = zcl_pp_conf=>mc_mess_id
*            number   = '052'
*            severity = if_abap_behv_message=>severity-error
*          )
*        ) TO reported-_header.
*
*      ELSE.
*
*        APPEND VALUE #(
*          %tky = <ls_header>-%tky
*          %msg = new_message(
*            id       = zcl_pp_conf=>mc_mess_id
*            number   = '053'
*            severity = if_abap_behv_message=>severity-error
*          )
*        ) TO reported-_header.
*
*      ENDIF.
*
*      RETURN.
*
*    ENDIF.
*
*    " YM_KURABIYE_SIMIT: Toplam KG * fırın firesi
*    IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_kurabiye_simit.
*
*      DATA(lv_header_material) = CONV matnr( |{ <ls_header>-material ALPHA = IN WIDTH = 18 }| ).
*
*      SELECT SINGLE firinfiresi
*        FROM zpp_t_conf_003
*        WHERE product = @lv_header_material
*        INTO @lv_firin_firesi.
*
*      IF sy-subrc <> 0 OR lv_firin_firesi IS INITIAL.
*
*        APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
*
*        APPEND VALUE #(
*          %tky = <ls_header>-%tky
*          %msg = new_message(
*            id       = zcl_pp_conf=>mc_mess_id
*            number   = '054'
*            severity = if_abap_behv_message=>severity-error
*          )
*        ) TO reported-_header.
*
*        RETURN.
*
*      ENDIF.
*
*      lv_prod_quantity = lv_total_kg * lv_firin_firesi.
*
*    ENDIF.
*
*    " YM_EE_LAHMACUN: Toplam KG direkt üretim miktarı
*    IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_ee_lahmacun.
*      lv_prod_quantity = lv_total_kg.
*    ENDIF.
*
*    " Üretim miktarı başlığa yazılır
*    MODIFY ENTITIES OF zpp_i_conf_h IN LOCAL MODE
*      ENTITY _header
*        UPDATE FIELDS ( productionquantity )
*        WITH VALUE #(
*          (
*            %tky = <ls_header>-%tky
*            productionquantity = lv_prod_quantity
*          )
*        )
*      FAILED DATA(lt_failed_update)
*      REPORTED DATA(lt_reported_update).
*
*    IF lt_failed_update-_header IS NOT INITIAL.
*
*      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
*
*      APPEND VALUE #(
*        %tky = <ls_header>-%tky
*        %msg = new_message(
*          id       = zcl_pp_conf=>mc_mess_id
*          number   = '055'
*          severity = if_abap_behv_message=>severity-error
*        )
*      ) TO reported-_header.
*
*      RETURN.
*
*    ENDIF.
*
*    APPEND VALUE #(
*      %tky = <ls_header>-%tky
*      %msg = new_message(
*        id       = zcl_pp_conf=>mc_mess_id
*        number   = '056'
*        severity = if_abap_behv_message=>severity-success
*      )
*    ) TO reported-_header.
*
*    " Güncel başlık sonucu döndürülür
*    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
*      ENTITY _header
*        ALL FIELDS
*        WITH CORRESPONDING #( keys )
*        RESULT DATA(lt_result).
*
*    result = VALUE #(
*      FOR ls_result IN lt_result
*      (
*        %tky   = ls_result-%tky
*        %param = ls_result
*      )
*    ).
*
*  ENDMETHOD.


  METHOD getprodquan.

    DATA: lv_total_kg      TYPE menge_d,
          lv_item_qty_kg   TYPE menge_d,
          lv_firin_firesi  TYPE zpp_i_conf_h-productionquantity,
          lv_prod_quantity TYPE zpp_i_conf_h-productionquantity,
          lv_has_error     TYPE abap_boolean.

    DATA lt_kepek_material TYPE SORTED TABLE OF matnr WITH UNIQUE KEY table_line.

    " Başlık ve kalemler okunur
    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _header
        FIELDS (
          confuuid
          material
          productiontype
          productionquantity
          baseunit
        )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_header)

      ENTITY _header BY \_items
        FIELDS (
          itemuuid
          confuuid
          componentmaterial
          quantity
          unit
          bomitemcat
        )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_item).

    READ TABLE lt_header ASSIGNING FIELD-SYMBOL(<ls_header>) INDEX 1.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    " Üretim türü kontrolü
    IF <ls_header>-productiontype <> zcl_pp_conf=>mc_ut_ym_kurabiye_simit
   AND <ls_header>-productiontype <> zcl_pp_conf=>mc_ut_ym_ee_lahmacun.

      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
      APPEND VALUE #( %tky = <ls_header>-%tky %msg = new_message( id = zcl_pp_conf=>mc_mess_id number = '048'
      severity = if_abap_behv_message=>severity-error ) ) TO reported-_header.  RETURN.
    ENDIF.

    IF lt_item IS INITIAL.
      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
      APPEND VALUE #( %tky = <ls_header>-%tky %msg = new_message( id = zcl_pp_conf=>mc_mess_id number   = '049'
          severity = if_abap_behv_message=>severity-error  ) ) TO reported-_header.
      RETURN.
    ENDIF.

    " YM_EE_LAHMACUN için kepek malzemeleri okunur
    IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_ee_lahmacun.

      SELECT malzeme
        FROM zpp_t_conf_014
        INTO TABLE @DATA(lt_t014).

      LOOP AT lt_t014 ASSIGNING FIELD-SYMBOL(<ls_t014>).
        INSERT CONV matnr( |{ <ls_t014>-malzeme ALPHA = IN WIDTH = 18 }| ) INTO TABLE lt_kepek_material.
      ENDLOOP.

    ENDIF.

    " Kalemler üretim türüne göre hesaplanır
    LOOP AT lt_item ASSIGNING FIELD-SYMBOL(<ls_item>).

      DATA(lv_component) = CONV matnr( |{ <ls_item>-componentmaterial ALPHA = IN WIDTH = 18 }| ).

      " YM_KURABIYE_SIMIT: sadece Z kalemler
      IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_kurabiye_simit
     AND <ls_item>-bomitemcat <> zcl_pp_conf=>mc_bomitemcat_z.
        CONTINUE.
      ENDIF.

      " YM_EE_LAHMACUN: Z kalemler veya kepek malzemeleri
*      IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_ee_lahmacun
*     AND <ls_item>-bomitemcat <> zcl_pp_conf=>mc_bomitemcat_z
*     AND NOT line_exists( lt_kepek_material[ table_line = lv_component ] ).
*        CONTINUE.
*      ENDIF.

      " YM_EE_LAHMACUN için ilgili kalem miktarı 0 olamaz
      IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_ee_lahmacun
     AND <ls_item>-quantity IS INITIAL.
        APPEND VALUE #( %tky = <ls_item>-%tky ) TO failed-_item.
        APPEND VALUE #( %tky = <ls_item>-%tky
          %msg = new_message(
            id       = zcl_pp_conf=>mc_mess_id
            number   = '050'
            severity = if_abap_behv_message=>severity-error
            v1       = |{ <ls_item>-componentmaterial ALPHA = OUT }|
          )
        ) TO reported-_item.
        lv_has_error = abap_true.
        CONTINUE.
      ENDIF.

      " YM_KURABIYE_SIMIT için 0 miktarlı Z kalemi hesaplamaya alma
      IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_kurabiye_simit
     AND <ls_item>-quantity IS INITIAL.
        CONTINUE.
      ENDIF.

      CLEAR lv_item_qty_kg.

      IF <ls_item>-unit = 'KG'.

        lv_item_qty_kg = <ls_item>-quantity.

      ELSEIF <ls_item>-unit = 'G'.

        lv_item_qty_kg = <ls_item>-quantity / 1000.

      ELSE.

        " KG olmayan birimler KG'ye çevrilir
        zcl_pp_conf=>convert_material_quantity(
          EXPORTING
            iv_product    = lv_component
            iv_source_qty = <ls_item>-quantity
            iv_source_uom = CONV msehi( <ls_item>-unit )
            iv_target_uom = CONV msehi( 'KG' )
          IMPORTING
            ev_target_qty = lv_item_qty_kg
        ).

        IF lv_item_qty_kg IS INITIAL.

          APPEND VALUE #( %tky = <ls_item>-%tky ) TO failed-_item.
          APPEND VALUE #(
            %tky = <ls_item>-%tky
            %msg = new_message(
              id       = zcl_pp_conf=>mc_mess_id
              number   = '051'
              severity = if_abap_behv_message=>severity-error
              v1       = |{ <ls_item>-componentmaterial ALPHA = OUT }|
            )
          ) TO reported-_item.

          lv_has_error = abap_true.
          CONTINUE.

        ENDIF.

      ENDIF.

      lv_total_kg = lv_total_kg + lv_item_qty_kg.

    ENDLOOP.

    IF lv_has_error = abap_true.
      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
      RETURN.
    ENDIF.

    IF lv_total_kg IS INITIAL.

      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
      IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_kurabiye_simit.
        APPEND VALUE #(
          %tky = <ls_header>-%tky
          %msg = new_message(
            id       = zcl_pp_conf=>mc_mess_id
            number   = '052'
            severity = if_abap_behv_message=>severity-error
          )
        ) TO reported-_header.
      ELSE.
        APPEND VALUE #(
          %tky = <ls_header>-%tky
          %msg = new_message(
            id       = zcl_pp_conf=>mc_mess_id
            number   = '053'
            severity = if_abap_behv_message=>severity-error
          )
        ) TO reported-_header.

      ENDIF.

      RETURN.

    ENDIF.

    " YM_KURABIYE_SIMIT: Toplam KG * fırın firesi
    " YM_EE_LAHMACUN: Toplam KG direkt üretim miktarı
    IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_kurabiye_simit OR
       <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_ee_lahmacun.

      DATA(lv_header_material) = CONV matnr( |{ <ls_header>-material ALPHA = IN WIDTH = 18 }| ).

      " Fırın Firesi/Katsayı tablosu olarak kullanıyoruz
      SELECT SINGLE firinfiresi
        FROM zpp_t_conf_003
        WHERE product = @lv_header_material
        INTO @lv_firin_firesi.

      IF sy-subrc <> 0 OR lv_firin_firesi IS INITIAL.

        APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.

        APPEND VALUE #(
          %tky = <ls_header>-%tky
          %msg = new_message(
            id       = zcl_pp_conf=>mc_mess_id
            number   = '054'
            severity = if_abap_behv_message=>severity-error
          )
        ) TO reported-_header.

        RETURN.

      ENDIF.

      lv_prod_quantity = lv_total_kg * lv_firin_firesi.

    ENDIF.

    " YM_EE_LAHMACUN: Toplam KG direkt üretim miktarı
*    IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_ee_lahmacun.
*      lv_prod_quantity = lv_total_kg.
*    ENDIF.

    " Üretim miktarı başlığa yazılır
    MODIFY ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _header
        UPDATE FIELDS ( productionquantity )
        WITH VALUE #(
          (
            %tky = <ls_header>-%tky
            productionquantity = lv_prod_quantity
          )
        )
      FAILED DATA(lt_failed_update)
      REPORTED DATA(lt_reported_update).

    IF lt_failed_update-_header IS NOT INITIAL.

      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.

      APPEND VALUE #(
        %tky = <ls_header>-%tky
        %msg = new_message(
          id       = zcl_pp_conf=>mc_mess_id
          number   = '055'
          severity = if_abap_behv_message=>severity-error
        )
      ) TO reported-_header.

      RETURN.

    ENDIF.

    APPEND VALUE #(
      %tky = <ls_header>-%tky
      %msg = new_message(
        id       = zcl_pp_conf=>mc_mess_id
        number   = '056'
        severity = if_abap_behv_message=>severity-success
      )
    ) TO reported-_header.

    " Güncel başlık sonucu döndürülür
    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _header
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_result).

    result = VALUE #(
      FOR ls_result IN lt_result
      (
        %tky   = ls_result-%tky
        %param = ls_result
      )
    ).

  ENDMETHOD.


  METHOD getmatcomponents.

    DATA lt_create TYPE TABLE FOR CREATE zpp_i_conf_h\_items.
    DATA lt_delete TYPE TABLE FOR DELETE zpp_i_conf_i.
    DATA lv_cid_no TYPE i.

    " Başlık verisini okud
    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _header
        FIELDS (
          confuuid
          plant
          material
          productionquantity
          baseunit
          productiontype
          multiplier
          closingshift
        )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_header)

      ENTITY _header BY \_items
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_existing_item).

    IF lt_header IS INITIAL.
      RETURN.
    ENDIF.
    READ TABLE lt_header ASSIGNING FIELD-SYMBOL(<ls_header>) INDEX 1.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    IF <ls_header>-material IS INITIAL.
      RETURN.
    ENDIF.

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " YM_KURABIYE_SIMIT için üretim miktarı boş/0 ise
    " sadece işlem içinde 1 kabul et
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    DATA(lv_effective_quantity) = <ls_header>-productionquantity.

    IF ( <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_kurabiye_simit OR
         <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_ee_lahmacun ) AND
      lv_effective_quantity < 1.
      lv_effective_quantity = 1.
    ENDIF.

    " YM_BOREK BOM Miktarı çarpan hesapla
    IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_borek.
      IF <ls_header>-multiplier > 0.
        lv_effective_quantity = <ls_header>-productionquantity * <ls_header>-multiplier.
      ELSE.
        APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
        APPEND VALUE #( %tky = <ls_header>-%tky %msg =
         new_message( id = zcl_pp_conf=>mc_mess_id number = '058' severity = if_abap_behv_message=>severity-error
         v1 = zcl_pp_conf=>mc_ut_ym_borek ) ) TO reported-_header. RETURN.
      ENDIF.
    ENDIF.

    IF lv_effective_quantity < 1.
      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
      APPEND VALUE #( %tky = <ls_header>-%tky %msg =
       new_message( id = zcl_pp_conf=>mc_mess_id number = '038' severity = if_abap_behv_message=>severity-error ) ) TO reported-_header. RETURN.
    ENDIF.


    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Eski kalemleri sil
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    lt_delete = VALUE #(
      FOR ls_item IN lt_existing_item
      (
        %tky      = ls_item-%tky
        %is_draft = ls_item-%is_draft
      )
    ).

    IF lt_delete IS NOT INITIAL.
      MODIFY ENTITIES OF zpp_i_conf_h IN LOCAL MODE
        ENTITY _item
          DELETE FROM lt_delete
        MAPPED DATA(mapped_delete)
        FAILED DATA(failed_delete)
        REPORTED DATA(reported_delete).
    ENDIF.


    DATA(lv_material) = CONV matnr( |{ <ls_header>-material ALPHA = IN WIDTH = 18 }| ).
    DATA(lv_quantity) = CONV menge_d( lv_effective_quantity ).

    DATA(lt_bom_result) = zcl_pp_conf=>explode_bom( iv_material = lv_material iv_quantity = lv_quantity ).
    IF lt_bom_result IS INITIAL.
      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
      APPEND VALUE #( %tky = <ls_header>-%tky %msg =
       new_message( id = zcl_pp_conf=>mc_mess_id number = '057' severity = if_abap_behv_message=>severity-error
       v1 = <ls_header>-material ) ) TO reported-_header. RETURN.
    ENDIF.

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " MAMUL_KURABIYE + BomItemCat = Z için ZPP_T_CONF_004 kontrolü
    " Mevcut kontrol korunuyor
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_mamul_kurabiye.

      SELECT c~mamul, c~yarimamul, c~arabakg
           FROM zpp_t_conf_004 AS c
           INNER JOIN @lt_bom_result AS l
             ON  c~mamul     = l~material
             AND c~yarimamul = l~component
           WHERE l~bom_item_cat = @zcl_pp_conf=>mc_bomitemcat_z
           INTO TABLE @DATA(lt_conf_004).

      " YM_EE_LAHMACUN için kepek malzemeleri okunur
    ELSEIF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_ee_lahmacun.

      SELECT malzeme  FROM zpp_t_conf_014 AS k
         INNER JOIN @lt_bom_result AS l ON k~malzeme = l~component
         INTO TABLE @DATA(lt_kepek).

    ENDIF.

    APPEND VALUE #( %tky = <ls_header>-%tky %is_draft = <ls_header>-%is_draft ) TO lt_create ASSIGNING FIELD-SYMBOL(<ls_create>).

    LOOP AT lt_bom_result ASSIGNING FIELD-SYMBOL(<ls_bom>).

      """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      " MAMUL_KURABIYE + Z ise ZPP_T_CONF_004 config zorunlu
      """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_mamul_kurabiye
      AND <ls_bom>-bom_item_cat     = zcl_pp_conf=>mc_bomitemcat_z.

        DATA(ls_conf_004) = VALUE #( lt_conf_004[ mamul = <ls_bom>-material yarimamul = <ls_bom>-component ] OPTIONAL ).
        IF ls_conf_004 IS INITIAL.
          APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
          APPEND VALUE #( %tky = <ls_header>-%tky
            %msg = new_message( id = zcl_pp_conf=>mc_mess_id number = '031' severity = if_abap_behv_message=>severity-error v1 = |{ <ls_bom>-component ALPHA = OUT }| ) ) TO reported-_header.
          CONTINUE.
        ENDIF.

      ENDIF.

      """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      " Default miktar: BOM miktarı
      """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      DATA(lv_item_quantity) = CONV zpp_i_conf_i-quantity( <ls_bom>-quantity ).

      DATA(lv_component) = CONV matnr( |{ <ls_bom>-component ALPHA = IN WIDTH = 18 }| ).
      DATA(ls_kepek) = VALUE #( lt_kepek[ malzeme = lv_component ] OPTIONAL ).

      """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      " Mevcut kural:
      " mamul_kurabiye , ym_borek , mamlu_ee_lahmacun + BomItemCat = Z ise miktar
      """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_mamul_kurabiye AND
         <ls_bom>-bom_item_cat = zcl_pp_conf=>mc_bomitemcat_z.
        lv_item_quantity = 0.
      ENDIF.
      " Elle doldurulacak
      IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_kurabiye_simit.
        lv_item_quantity = 0.
      ENDIF.
      IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_ee_lahmacun AND
         <ls_bom>-bom_item_cat <> zcl_pp_conf=>mc_bomitemcat_z.
        lv_item_quantity = 0.
      ENDIF.
      IF (  <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_borek OR
            <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_ee_lahmacun OR
            <ls_header>-productiontype = zcl_pp_conf=>mc_ut_mamul_ee_lahmacun ) AND
            <ls_bom>-bom_item_cat      = zcl_pp_conf=>mc_bomitemcat_z AND
            <ls_header>-closingshift   = abap_true.
        SELECT SUM( stockqty )
            FROM zpp_i_batch_stock_vh
            WHERE product         = @lv_component
              AND storagelocation = @<ls_bom>-storage_location
            INTO @DATA(lv_total_stock_raw).
        lv_item_quantity = CONV zpp_i_conf_i-quantity( lv_total_stock_raw  ).
      ENDIF.

      """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      " YM_BOREK + BomItemCat = Z + Son Vardiya seçili değilse
      " - ZPP_T_CONF_006-STKKLNSABITMIK kontrolü
      """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

      IF ( ( <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_borek OR
             <ls_header>-productiontype = zcl_pp_conf=>mc_ut_mamul_ee_lahmacun ) AND
             <ls_bom>-bom_item_cat      = zcl_pp_conf=>mc_bomitemcat_z AND
             <ls_header>-closingshift  <> abap_true )
       OR
        ( <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_ee_lahmacun AND
          <ls_bom>-bom_item_cat      = zcl_pp_conf=>mc_bomitemcat_z AND
          <ls_header>-closingshift  <> abap_true ) .

        SELECT SUM( stockqty )
          FROM zpp_i_batch_stock_vh
          WHERE product         = @lv_component
            AND storagelocation = @<ls_bom>-storage_location
          INTO @lv_total_stock_raw.

        DATA(lv_total_stock) = CONV zpp_i_conf_i-quantity( lv_total_stock_raw  ).
        CLEAR lv_total_stock_raw.
        DATA(lv_mamul) = CONV matnr( |{ <ls_header>-material ALPHA = IN WIDTH = 18 }| ).

        SELECT SINGLE stkklnsabitmik
          FROM zpp_t_conf_006
          WHERE yarimamul    = @lv_mamul
            AND altyarimamul = @lv_component
          INTO @DATA(lv_sabit_mik).
        IF sy-subrc <> 0.

          APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
          APPEND VALUE #( %tky = <ls_header>-%tky
            %msg = new_message( id = zcl_pp_conf=>mc_mess_id number = '035' severity = if_abap_behv_message=>severity-error v1 = |{ <ls_bom>-component ALPHA = OUT }| ) ) TO reported-_header.
          CONTINUE.
        ENDIF.

        lv_item_quantity = CONV zpp_i_conf_i-quantity( lv_total_stock - lv_sabit_mik  ).
        IF lv_item_quantity <= 0.
*          APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
          APPEND VALUE #( %tky = <ls_header>-%tky
            %msg = new_message(
              id       = zcl_pp_conf=>mc_mess_id
              number   = '036'
              severity = if_abap_behv_message=>severity-error
              v1       = |{ <ls_bom>-component ALPHA = OUT }|
              v2       = |{ lv_item_quantity }| )
          ) TO reported-_item.
*          CONTINUE.
        ENDIF.

      ENDIF.

      lv_cid_no += 1.

      APPEND VALUE #(
        %cid      = |ITEM_{ lv_cid_no }|
        %is_draft = <ls_header>-%is_draft
        itemno               = <ls_bom>-bom_item_number
        componentmaterial    = |{ <ls_bom>-component ALPHA = OUT }|
        componentdescription = <ls_bom>-component_text
        storagelocation      = <ls_bom>-storage_location
        quantity             = COND #( WHEN lv_item_quantity <= 0 THEN 0 ELSE lv_item_quantity )
        unit                 = <ls_bom>-unit
        batch                = ''
        bomitemcat           = <ls_bom>-bom_item_cat
        isbatchmngmntrequired  = <ls_bom>-isbatchmanagementrequired
      ) TO <ls_create>-%target.

    ENDLOOP.

    CHECK failed-_header IS INITIAL.


    IF lt_create IS NOT INITIAL.
      lcl_buffer=>gv_skip_fillcomponentdata = abap_true.
      MODIFY ENTITIES OF zpp_i_conf_h IN LOCAL MODE
        ENTITY _header
          CREATE BY \_items
          FIELDS (
            itemno
            componentmaterial
            componentdescription
            storagelocation
            batch
            quantity
            unit
            bomitemcat
            isbatchmngmntrequired
          )
          WITH lt_create
        MAPPED DATA(mapped_create)
        FAILED DATA(failed_create)
        REPORTED DATA(reported_create).
      lcl_buffer=>gv_skip_fillcomponentdata = abap_false.
    ENDIF.

    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _header
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_result).

    result = VALUE #(
      FOR ls_result IN lt_result
      (
        %tky   = ls_result-%tky
        %param = ls_result
      )
    ).

  ENDMETHOD.

  METHOD definebatch.

    TYPES: BEGIN OF ty_required,
             componentmaterial     TYPE zpp_i_conf_i-componentmaterial,
             componentmaterial_in  TYPE matnr,
             componentdescription  TYPE zpp_i_conf_i-componentdescription,
             storagelocation       TYPE zpp_i_conf_i-storagelocation,
             quantity              TYPE zpp_i_conf_i-quantity,
             unit                  TYPE zpp_i_conf_i-unit,
             bomitemcat            TYPE zpp_i_conf_i-bomitemcat,
             isbatchmngmntrequired TYPE zpp_i_conf_i-isbatchmngmntrequired,
           END OF ty_required.

    TYPES tt_required TYPE SORTED TABLE OF ty_required
      WITH UNIQUE KEY componentmaterial_in storagelocation.

    TYPES: BEGIN OF ty_stock,
             product              TYPE zpp_i_batch_stock_vh-product,
             storagelocation      TYPE zpp_i_batch_stock_vh-storagelocation,
             batch                TYPE zpp_i_batch_stock_vh-batch,
             stockqty             TYPE zpp_i_conf_i-quantity,
             materialbaseunit     TYPE zpp_i_batch_stock_vh-materialbaseunit,
             lastgoodsreceiptdate TYPE i_batchdistinct-lastgoodsreceiptdate,
           END OF ty_stock.

    TYPES tt_stock TYPE STANDARD TABLE OF ty_stock WITH EMPTY KEY.

    TYPES: BEGIN OF ty_alloc,
             componentmaterial     TYPE zpp_i_conf_i-componentmaterial,
             componentdescription  TYPE zpp_i_conf_i-componentdescription,
             storagelocation       TYPE zpp_i_conf_i-storagelocation,
             batch                 TYPE zpp_i_conf_i-batch,
             quantity              TYPE zpp_i_conf_i-quantity,
             unit                  TYPE zpp_i_conf_i-unit,
             bomitemcat            TYPE zpp_i_conf_i-bomitemcat,
             isbatchmngmntrequired TYPE zpp_i_conf_i-isbatchmngmntrequired,
           END OF ty_alloc.

    DATA lt_required TYPE tt_required.
    DATA lt_stock    TYPE tt_stock.
    DATA lt_alloc    TYPE STANDARD TABLE OF ty_alloc WITH EMPTY KEY.

    DATA lt_delete TYPE TABLE FOR DELETE zpp_i_conf_i.
    DATA lt_create TYPE TABLE FOR CREATE zpp_i_conf_h\_items.

    DATA lv_item_no              TYPE i.
    DATA lv_cid_no               TYPE i.
    DATA lv_has_validation_error TYPE abap_boolean.
    DATA lv_component_in         TYPE matnr.
    DATA lv_remaining            TYPE zpp_i_conf_i-quantity.
    DATA lv_take_qty             TYPE zpp_i_conf_i-quantity.

    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _header
        FIELDS (
          confuuid
          material
          productiontype
        )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_header)

      ENTITY _header BY \_items
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item).

    READ TABLE lt_header ASSIGNING FIELD-SYMBOL(<ls_header>) INDEX 1.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    IF lt_item IS INITIAL.

      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
      APPEND VALUE #( %tky = <ls_header>-%tky
        %msg = new_message( id = zcl_pp_conf=>mc_mess_id  number = '021' severity = if_abap_behv_message=>severity-error  )  ) TO reported-_header.
      RETURN.

    ENDIF.

    LOOP AT lt_item ASSIGNING FIELD-SYMBOL(<ls_item>).

      IF <ls_item>-componentmaterial IS INITIAL
      OR <ls_item>-storagelocation   IS INITIAL
      OR <ls_item>-quantity          IS INITIAL.

        APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
        APPEND VALUE #( %tky = <ls_item>-%tky %msg = new_message( id = zcl_pp_conf=>mc_mess_id number = '022' severity = if_abap_behv_message=>severity-error ) ) TO reported-_item.
        lv_has_validation_error = abap_true.
        CONTINUE.
      ENDIF.

      " Kaldırıldı 19.06.2026
*    IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_mamul_kurabiye
*    AND <ls_item>-bomitemcat = zcl_pp_conf=>mc_bomitemcat_z
*    AND <ls_item>-carcount < 1.
*
*      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
*
*      APPEND VALUE #(
*        %tky = <ls_item>-%tky
*        %msg = new_message(
*          id       = zcl_pp_conf=>mc_mess_id
*          number   = '034'
*          severity = if_abap_behv_message=>severity-error
*        )
*      ) TO reported-_item.
*
*      lv_has_validation_error = abap_true.
*      CONTINUE.
*
*    ENDIF.

      CHECK <ls_item>-isbatchmngmntrequired EQ abap_true.

      lv_component_in = CONV matnr( |{ <ls_item>-componentmaterial ALPHA = IN WIDTH = 18 }| ).

      READ TABLE lt_required ASSIGNING FIELD-SYMBOL(<ls_required>)
        WITH TABLE KEY
          componentmaterial_in = lv_component_in
          storagelocation      = <ls_item>-storagelocation.
      IF sy-subrc = 0.
        IF <ls_required>-unit <> <ls_item>-unit.

          APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
          APPEND VALUE #( %tky = <ls_item>-%tky  %msg = new_message( id = zcl_pp_conf=>mc_mess_id number = '023'
           severity = if_abap_behv_message=>severity-error v1 = <ls_item>-componentmaterial v2 = <ls_item>-storagelocation ) ) TO reported-_item.
          lv_has_validation_error = abap_true.
          CONTINUE.
        ENDIF.

        " Aynı malzeme + depo için ihtiyaç miktarı toplanır
        <ls_required>-quantity = <ls_required>-quantity + <ls_item>-quantity.

        IF <ls_required>-componentdescription IS INITIAL
        AND <ls_item>-componentdescription IS NOT INITIAL.
          <ls_required>-componentdescription = <ls_item>-componentdescription.
        ENDIF.

        IF <ls_required>-bomitemcat IS INITIAL.
          <ls_required>-bomitemcat = <ls_item>-bomitemcat.
        ENDIF.

      ELSE.

        INSERT VALUE #(
          componentmaterial    = |{ lv_component_in ALPHA = OUT }|
          componentmaterial_in = lv_component_in
          componentdescription = <ls_item>-componentdescription
          storagelocation      = <ls_item>-storagelocation
          quantity             = <ls_item>-quantity
          unit                 = <ls_item>-unit
          bomitemcat           = <ls_item>-bomitemcat
          isbatchmngmntrequired = <ls_item>-isbatchmngmntrequired
        ) INTO TABLE lt_required.

      ENDIF.

    ENDLOOP.

    IF lv_has_validation_error = abap_true.
      RETURN.
    ENDIF.

    IF lt_required IS INITIAL.
      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
      APPEND VALUE #( %tky = <ls_header>-%tky  %msg = new_message( id = zcl_pp_conf=>mc_mess_id number = '024' severity = if_abap_behv_message=>severity-error ) ) TO reported-_header.
      RETURN.
    ENDIF.

    " Stokları oku ve FIFO tarihini al
    SELECT stock~product,
           stock~storagelocation,
           stock~batch,
           stock~stockqty,
           stock~materialbaseunit,
           batch~lastgoodsreceiptdate
      FROM zpp_i_batch_stock_vh AS stock
      INNER JOIN i_batchdistinct AS batch
        ON  batch~material = stock~product
        AND batch~batch    = stock~batch
      FOR ALL ENTRIES IN @lt_required
      WHERE stock~product         = @lt_required-componentmaterial_in
        AND stock~storagelocation = @lt_required-storagelocation
        AND stock~stockqty        > 0
      INTO TABLE @lt_stock.

    SORT lt_stock BY product
                     storagelocation
                     lastgoodsreceiptdate ASCENDING
                     batch ASCENDING.

    " FIFO dağıtımı
    LOOP AT lt_required ASSIGNING <ls_required>.

      lv_remaining = <ls_required>-quantity.

      LOOP AT lt_stock ASSIGNING FIELD-SYMBOL(<ls_stock>)
        WHERE product         = <ls_required>-componentmaterial_in
          AND storagelocation = <ls_required>-storagelocation.

        IF lv_remaining <= 0.
          EXIT.
        ENDIF.

        IF <ls_stock>-stockqty IS INITIAL OR <ls_stock>-stockqty <= 0.
          CONTINUE.
        ENDIF.

        IF lv_remaining > <ls_stock>-stockqty.
          lv_take_qty = <ls_stock>-stockqty.
        ELSE.
          lv_take_qty = lv_remaining.
        ENDIF.

        IF lv_take_qty <= 0.
          CONTINUE.
        ENDIF.

        APPEND VALUE #(
          componentmaterial    = |{ <ls_required>-componentmaterial_in ALPHA = OUT }|
          componentdescription = <ls_required>-componentdescription
          storagelocation      = <ls_required>-storagelocation
          batch                = <ls_stock>-batch
          quantity             = lv_take_qty
          unit                 = <ls_required>-unit
          bomitemcat           = <ls_required>-bomitemcat
          isbatchmngmntrequired = <ls_required>-isbatchmngmntrequired
        ) TO lt_alloc.

        lv_remaining = lv_remaining - lv_take_qty.

      ENDLOOP.

      IF lv_remaining > 0.

        " Stok yetmeyen miktar partisiz satır olarak kalır
        APPEND VALUE #(
          componentmaterial    = |{ <ls_required>-componentmaterial_in ALPHA = OUT }|
          componentdescription = <ls_required>-componentdescription
          storagelocation      = <ls_required>-storagelocation
          batch                = ''
          quantity             = lv_remaining
          unit                 = <ls_required>-unit
          bomitemcat           = <ls_required>-bomitemcat
          isbatchmngmntrequired = <ls_required>-isbatchmngmntrequired
        ) TO lt_alloc.

        APPEND VALUE #( %tky = <ls_header>-%tky
          %msg = new_message( id = zcl_pp_conf=>mc_mess_id  number = '005' severity = if_abap_behv_message=>severity-error
          v1 = <ls_required>-componentmaterial v2  = <ls_required>-storagelocation ) ) TO reported-_header.



        APPEND VALUE #(
          %tky = <ls_header>-%tky
          %msg = new_message(
            id       = zcl_pp_conf=>mc_mess_id
            number   = '025'
            severity = if_abap_behv_message=>severity-error
            v1       = <ls_required>-componentmaterial
            v2       = <ls_required>-storagelocation
          )
        ) TO reported-_header.
        APPEND VALUE #(    %tky = <ls_header>-%tky
          %msg = new_message( id = zcl_pp_conf=>mc_mess_id  number = '026' severity = if_abap_behv_message=>severity-error  v1 = lv_remaining v2  = <ls_required>-unit ) ) TO reported-_header.

      ENDIF.

    ENDLOOP.

    IF lt_alloc IS INITIAL.
      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
      APPEND VALUE #( %tky = <ls_header>-%tky
        %msg = new_message( id   = zcl_pp_conf=>mc_mess_id number   = '027' severity = if_abap_behv_message=>severity-error )  ) TO reported-_header.
      RETURN.
    ENDIF.

    " Eski kalemleri sil
    lt_delete = VALUE #(
      FOR ls_item IN lt_item
      (
        %tky      = ls_item-%tky
        %is_draft = ls_item-%is_draft
      )
    ).

    IF lt_delete IS NOT INITIAL.

      MODIFY ENTITIES OF zpp_i_conf_h IN LOCAL MODE
        ENTITY _item
          DELETE FROM lt_delete
        MAPPED DATA(mapped_delete)
        FAILED DATA(failed_delete)
        REPORTED DATA(reported_delete).

      IF failed_delete-_item IS NOT INITIAL.

        APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
        APPEND VALUE #( %tky = <ls_header>-%tky  %msg = new_message(
            id       = zcl_pp_conf=>mc_mess_id  number   = '028'  severity = if_abap_behv_message=>severity-error  )  ) TO reported-_header.
        RETURN.
      ENDIF.

    ENDIF.

    " Yeni kalemleri oluştur
    APPEND VALUE #(
      %tky      = <ls_header>-%tky
      %is_draft = <ls_header>-%is_draft
    ) TO lt_create ASSIGNING FIELD-SYMBOL(<ls_create>).

    LOOP AT lt_alloc ASSIGNING FIELD-SYMBOL(<ls_alloc>).

      lv_item_no += 10.
      lv_cid_no  += 1.

      APPEND VALUE #(
        %cid      = |FIFO_{ lv_cid_no }|
        %is_draft = <ls_header>-%is_draft

        itemno               = CONV #( lv_item_no )
        componentmaterial    = <ls_alloc>-componentmaterial
        componentdescription = <ls_alloc>-componentdescription
        storagelocation      = <ls_alloc>-storagelocation
        batch                = <ls_alloc>-batch
        quantity             = <ls_alloc>-quantity
        unit                 = <ls_alloc>-unit
        carcount             = 0
        bomitemcat           = <ls_alloc>-bomitemcat
        isbatchmngmntrequired  = abap_true
      ) TO <ls_create>-%target.

    ENDLOOP.

    " Parti ilşkisiz kalemleri direkt ekle
    LOOP AT lt_item ASSIGNING <ls_item>
      WHERE isbatchmngmntrequired = abap_false.

      lv_item_no += 10.
      lv_cid_no  += 1.

      APPEND VALUE #(
      %cid      = |FIFO_{ lv_cid_no }|
      %is_draft = <ls_header>-%is_draft

      itemno               = CONV #( lv_item_no )
      componentmaterial    = <ls_item>-componentmaterial
      componentdescription = <ls_item>-componentdescription
      storagelocation      = <ls_item>-storagelocation
      batch                = <ls_item>-batch
      quantity             = <ls_item>-quantity
      unit                 = <ls_item>-unit
      carcount             = 0
      bomitemcat           = <ls_item>-bomitemcat
      isbatchmngmntrequired  = abap_false
    ) TO <ls_create>-%target.
    ENDLOOP.

    MODIFY ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _header
        CREATE BY \_items
        FIELDS (
          itemno
          componentmaterial
          componentdescription
          storagelocation
          batch
          quantity
          unit
          carcount
          bomitemcat
          isbatchmngmntrequired
        )
        WITH lt_create
      MAPPED DATA(mapped_create)
      FAILED DATA(failed_create)
      REPORTED DATA(reported_create).

    IF failed_create-_item IS NOT INITIAL.

      APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.

      APPEND VALUE #(
        %tky = <ls_header>-%tky
        %msg = new_message(
          id       = zcl_pp_conf=>mc_mess_id
          number   = '029'
          severity = if_abap_behv_message=>severity-error
        )
      ) TO reported-_header.

      RETURN.

    ENDIF.

    APPEND VALUE #(
      %tky = <ls_header>-%tky
      %msg = new_message(
        id       = zcl_pp_conf=>mc_mess_id
        number   = '030'
        severity = if_abap_behv_message=>severity-success
      )
    ) TO reported-_header.

    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _header
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #(
      FOR ls_result IN lt_result
      (
        %tky   = ls_result-%tky
        %param = ls_result
      )
    ).

  ENDMETHOD.

*  METHOD definebatch.
*
*    TYPES: BEGIN OF ty_required,
*             componentmaterial    TYPE zpp_i_conf_i-componentmaterial,
*             componentmaterial_in TYPE matnr,
*             componentdescription TYPE zpp_i_conf_i-componentdescription,
*             storagelocation      TYPE zpp_i_conf_i-storagelocation,
*             quantity             TYPE zpp_i_conf_i-quantity,
*             unit                 TYPE zpp_i_conf_i-unit,
*           END OF ty_required.
*
*    TYPES tt_required TYPE SORTED TABLE OF ty_required
*      WITH UNIQUE KEY componentmaterial_in storagelocation.
*
*    TYPES: BEGIN OF ty_stock,
*             product              TYPE zpp_i_batch_stock_vh-product,
*             storagelocation      TYPE zpp_i_batch_stock_vh-storagelocation,
*             batch                TYPE zpp_i_batch_stock_vh-batch,
*             stockqty             TYPE zpp_i_batch_stock_vh-stockqty,
*             materialbaseunit     TYPE zpp_i_batch_stock_vh-materialbaseunit,
*             lastgoodsreceiptdate TYPE i_batchdistinct-lastgoodsreceiptdate,
*           END OF ty_stock.
*
*    TYPES tt_stock TYPE STANDARD TABLE OF ty_stock WITH EMPTY KEY.
*
*    TYPES: BEGIN OF ty_alloc,
*             componentmaterial    TYPE zpp_i_conf_i-componentmaterial,
*             componentdescription TYPE zpp_i_conf_i-componentdescription,
*             storagelocation      TYPE zpp_i_conf_i-storagelocation,
*             batch                TYPE zpp_i_conf_i-batch,
*             quantity             TYPE zpp_i_conf_i-quantity,
*             unit                 TYPE zpp_i_conf_i-unit,
*             stockqty             TYPE zpp_i_conf_i-actualstockquantity,
*           END OF ty_alloc.
*
*    DATA lt_required TYPE tt_required.
*    DATA lt_stock    TYPE tt_stock.
*    DATA lt_alloc    TYPE STANDARD TABLE OF ty_alloc WITH EMPTY KEY.
*
*    DATA lt_delete TYPE TABLE FOR DELETE zpp_i_conf_i.
*    DATA lt_create TYPE TABLE FOR CREATE zpp_i_conf_h\_items.
*
*    DATA lv_item_no              TYPE i.
*    DATA lv_cid_no               TYPE i.
*    DATA lv_has_validation_error TYPE abap_boolean.
*    DATA lv_component_in         TYPE matnr.
*    DATA lv_remaining            TYPE zpp_i_conf_i-quantity.
*    DATA lv_take_qty             TYPE zpp_i_conf_i-quantity.
*
*    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
*      ENTITY _header
*        FIELDS (
*          confuuid
*          material
*          productiontype
*        )
*        WITH CORRESPONDING #( keys )
*      RESULT DATA(lt_header)
*
*      ENTITY _header BY \_items
*        ALL FIELDS
*        WITH CORRESPONDING #( keys )
*      RESULT DATA(lt_item).
*
*    READ TABLE lt_header ASSIGNING FIELD-SYMBOL(<ls_header>) INDEX 1.
*    IF sy-subrc <> 0.
*      RETURN.
*    ENDIF.
*
*    IF lt_item IS INITIAL.
*
*      APPEND VALUE #(
*        %tky = <ls_header>-%tky
*      ) TO failed-_header.
*
*      APPEND VALUE #( %tky = <ls_header>-%tky
*          %msg = new_message(
*            id       = zcl_pp_conf=>mc_mess_id
*            number   = '021'
*            severity = if_abap_behv_message=>severity-error
*          )
*        ) TO reported-_header.
*      RETURN.
*
*    ENDIF.
*
*
*    LOOP AT lt_item ASSIGNING FIELD-SYMBOL(<ls_item>).
*
*      IF <ls_item>-componentmaterial IS INITIAL
*      OR <ls_item>-storagelocation   IS INITIAL
*      OR <ls_item>-quantity          IS INITIAL.
*
*        APPEND VALUE #(
*          %tky = <ls_header>-%tky
*        ) TO failed-_header.
*
*        APPEND VALUE #( %tky = <ls_header>-%tky
*         %msg = new_message(
*           id       = zcl_pp_conf=>mc_mess_id
*           number   = '022'
*           severity = if_abap_behv_message=>severity-error
*         )
*       ) TO reported-_item.
*
*        lv_has_validation_error = abap_true.
*        CONTINUE.
*
*      ENDIF.
*
*      IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_mamul_kurabiye AND
*         <ls_item>-bomitemcat = zcl_pp_conf=>mc_bomitemcat_z AND
*         <ls_item>-carcount < 1.
*        APPEND VALUE #( %tky = <ls_header>-%tky
*          %msg     = new_message(
*          id       = zcl_pp_conf=>mc_mess_id
*          number   = '034'
*          severity = if_abap_behv_message=>severity-error ) ) TO reported-_item.
*      ENDIF.
*
*
*      lv_component_in = CONV matnr( |{ <ls_item>-componentmaterial ALPHA = IN WIDTH = 18 }| ).
*
*      READ TABLE lt_required ASSIGNING FIELD-SYMBOL(<ls_required>)
*        WITH TABLE KEY
*          componentmaterial_in = lv_component_in
*          storagelocation      = <ls_item>-storagelocation.
*
*      IF sy-subrc = 0.
*
*        IF <ls_required>-unit <> <ls_item>-unit.
*
*          APPEND VALUE #(
*            %tky = <ls_header>-%tky
*          ) TO failed-_header.
*
*          APPEND VALUE #( %tky = <ls_header>-%tky
*            %msg = new_message(
*              id       = zcl_pp_conf=>mc_mess_id
*              number   = '022'
*              severity = if_abap_behv_message=>severity-error
*              v1 = <ls_item>-componentmaterial
*              v2 = <ls_item>-storagelocation
*            )
*          ) TO reported-_item.
*
*          lv_has_validation_error = abap_true.
*          CONTINUE.
*
*        ENDIF.
*
*        "COLLECT mantığı: aynı malzeme + depo için miktarı topla
*        <ls_required>-quantity += <ls_item>-quantity.
*
*        IF <ls_required>-componentdescription IS INITIAL
*        AND <ls_item>-componentdescription IS NOT INITIAL.
*          <ls_required>-componentdescription = <ls_item>-componentdescription.
*        ENDIF.
*
*      ELSE.
*
*        INSERT VALUE #(
*          componentmaterial    = |{ lv_component_in ALPHA = OUT }|
*          componentmaterial_in = lv_component_in
*          componentdescription = <ls_item>-componentdescription
*          storagelocation      = <ls_item>-storagelocation
*          quantity             = <ls_item>-quantity
*          unit                 = <ls_item>-unit
*        ) INTO TABLE lt_required.
*
*      ENDIF.
*
*    ENDLOOP.
*
*    IF lv_has_validation_error = abap_true.
*      RETURN.
*    ENDIF.
*
*    IF lt_required IS INITIAL.
*
*      APPEND VALUE #(
*        %tky = <ls_header>-%tky
*      ) TO failed-_header.
*
*
*      APPEND VALUE #( %tky = <ls_header>-%tky
*           %msg = new_message(
*             id       = zcl_pp_conf=>mc_mess_id
*             number   = '024'
*             severity = if_abap_behv_message=>severity-error
*           )
*         ) TO reported-_header.
*
*      RETURN.
*
*    ENDIF.
*
*    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
*    " 2. Stokları oku ve I_BatchDistinct ile FIFO tarihini al
*    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
*    SELECT stock~product,
*           stock~storagelocation,
*           stock~batch,
*           stock~stockqty,
*           stock~materialbaseunit,
*           batch~lastgoodsreceiptdate
*      FROM zpp_i_batch_stock_vh AS stock
*      INNER JOIN i_batchdistinct AS batch
*        ON  batch~material = stock~product
*        AND batch~batch    = stock~batch
*      FOR ALL ENTRIES IN @lt_required
*      WHERE stock~product         = @lt_required-componentmaterial_in
*        AND stock~storagelocation = @lt_required-storagelocation
*        AND stock~stockqty        > 0
*      INTO TABLE @lt_stock.
*
*    SORT lt_stock BY product
*                     storagelocation
*                     lastgoodsreceiptdate ASCENDING
*                     batch ASCENDING.
*
*    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
*    " 3. FIFO dağıtımını hesapla
*    "    Toplam ihtiyaç miktarından FIFO stokları düş.
*    "    Stok yetmezse kalan miktarı partisiz satır olarak bırak.
*    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
*    LOOP AT lt_required ASSIGNING <ls_required>.
*
*      lv_remaining = <ls_required>-quantity.
*
*      LOOP AT lt_stock ASSIGNING FIELD-SYMBOL(<ls_stock>)
*        WHERE product         = <ls_required>-componentmaterial_in
*          AND storagelocation = <ls_required>-storagelocation.
*
*        IF lv_remaining <= 0.
*          EXIT.
*        ENDIF.
*
*        IF <ls_stock>-stockqty <= 0.
*          CONTINUE.
*        ENDIF.
*
*        IF lv_remaining > <ls_stock>-stockqty.
*          lv_take_qty = <ls_stock>-stockqty.
*        ELSE.
*          lv_take_qty = lv_remaining.
*        ENDIF.
*
*        IF lv_take_qty <= 0.
*          CONTINUE.
*        ENDIF.
*
*        APPEND VALUE #(
*          componentmaterial    = |{ <ls_required>-componentmaterial_in ALPHA = OUT }|
*          componentdescription = <ls_required>-componentdescription
*          storagelocation      = <ls_required>-storagelocation
*          batch                = <ls_stock>-batch
*          quantity             = lv_take_qty
*          unit                 = <ls_required>-unit
*          stockqty             = <ls_stock>-stockqty
*        ) TO lt_alloc.
*
*        lv_remaining -= lv_take_qty.
*
*      ENDLOOP.
*
*      IF lv_remaining > 0.
*
*        "Stok yetmeyen miktar partisiz satır olarak kalır
*        APPEND VALUE #(
*          componentmaterial    = |{ <ls_required>-componentmaterial_in ALPHA = OUT }|
*          componentdescription = <ls_required>-componentdescription
*          storagelocation      = <ls_required>-storagelocation
*          batch                = ''
*          quantity             = lv_remaining
*          unit                 = <ls_required>-unit
*          stockqty             = 0
*        ) TO lt_alloc.
*
*        APPEND VALUE #(
*          %tky = <ls_header>-%tky
*          %msg = new_message_with_text(
*            severity = if_abap_behv_message=>severity-warning
*            text     = |{ <ls_required>-componentmaterial } / { <ls_required>-storagelocation } için yetersiz stok!|
*          )
*        ) TO reported-_header.
*
*        APPEND VALUE #( %tky = <ls_header>-%tky
*          %msg = new_message(
*            id       = zcl_pp_conf=>mc_mess_id
*            number   = '025'
*            severity = if_abap_behv_message=>severity-error
*            v1 =  <ls_required>-componentmaterial
*            v2 =  <ls_required>-storagelocation
*          )
*        ) TO reported-_header.
*
*        APPEND VALUE #( %tky = <ls_header>-%tky
*          %msg = new_message(
*            id       = zcl_pp_conf=>mc_mess_id
*            number   = '026'
*            severity = if_abap_behv_message=>severity-error
*            v1 =  lv_remaining
*            v2 =  <ls_required>-unit
*          )
*        ) TO reported-_header.
*
*
*      ENDIF.
*
*    ENDLOOP.
*
*    IF lt_alloc IS INITIAL.
*
*      APPEND VALUE #(
*        %tky = <ls_header>-%tky
*      ) TO failed-_header.
*
*
*      APPEND VALUE #( %tky = <ls_header>-%tky
*          %msg = new_message(
*            id       = zcl_pp_conf=>mc_mess_id
*            number   = '027'
*            severity = if_abap_behv_message=>severity-error
*          )
*        ) TO reported-_header.
*
*      RETURN.
*
*    ENDIF.
*
*    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
*    " 4. Allocation hazırlandıktan sonra eski kalemleri sil
*    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
*    lt_delete = VALUE #(
*      FOR ls_item IN lt_item
*      (
*        %tky      = ls_item-%tky
*        %is_draft = ls_item-%is_draft
*      )
*    ).
*
*    IF lt_delete IS NOT INITIAL.
*
*      MODIFY ENTITIES OF zpp_i_conf_h IN LOCAL MODE
*        ENTITY _item
*          DELETE FROM lt_delete
*        MAPPED DATA(mapped_delete)
*        FAILED DATA(failed_delete)
*        REPORTED DATA(reported_delete).
*
*      IF failed_delete-_item IS NOT INITIAL.
*
*        APPEND VALUE #(
*          %tky = <ls_header>-%tky
*        ) TO failed-_header.
*
*
*        APPEND VALUE #( %tky = <ls_header>-%tky
*          %msg = new_message(
*            id       = zcl_pp_conf=>mc_mess_id
*            number   = '028'
*            severity = if_abap_behv_message=>severity-error
*          )
*        ) TO reported-_header.
*
*        RETURN.
*
*      ENDIF.
*
*    ENDIF.
*
*    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
*    " 5. FIFO sonucuna göre yeni bileşen kalemlerini oluştur
*    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
*    APPEND VALUE #(
*      %tky      = <ls_header>-%tky
*      %is_draft = <ls_header>-%is_draft
*    ) TO lt_create ASSIGNING FIELD-SYMBOL(<ls_create>).
*
*    LOOP AT lt_alloc ASSIGNING FIELD-SYMBOL(<ls_alloc>).
*
*      lv_item_no += 10.
*      lv_cid_no  += 1.
*
*      APPEND VALUE #(
*        %cid      = |FIFO_{ lv_cid_no }|
*        %is_draft = <ls_header>-%is_draft
*
*        itemno               = CONV #( lv_item_no )
*        componentmaterial    = <ls_alloc>-componentmaterial
*        componentdescription = <ls_alloc>-componentdescription
*        storagelocation      = <ls_alloc>-storagelocation
*        batch                = <ls_alloc>-batch
*        quantity             = <ls_alloc>-quantity
*        unit                 = <ls_alloc>-unit
*        carcount             = 0
*        actualstockquantity  = <ls_alloc>-stockqty
*      ) TO <ls_create>-%target.
*
*    ENDLOOP.
*
*    MODIFY ENTITIES OF zpp_i_conf_h IN LOCAL MODE
*      ENTITY _header
*        CREATE BY \_items
*        FIELDS (
*          itemno
*          componentmaterial
*          componentdescription
*          storagelocation
*          batch
*          quantity
*          unit
*          carcount
*          actualstockquantity
*        )
*        WITH lt_create
*      MAPPED DATA(mapped_create)
*      FAILED DATA(failed_create)
*      REPORTED DATA(reported_create).
*
*    IF failed_create-_item IS NOT INITIAL.
*
*      APPEND VALUE #(
*        %tky = <ls_header>-%tky
*      ) TO failed-_header.
*
*
*      APPEND VALUE #( %tky = <ls_header>-%tky
*         %msg = new_message(
*           id       = zcl_pp_conf=>mc_mess_id
*           number   = '029'
*           severity = if_abap_behv_message=>severity-error
*         )
*       ) TO reported-_header.
*
*      RETURN.
*
*    ENDIF.
*
*
*    APPEND VALUE #( %tky = <ls_header>-%tky
*         %msg = new_message(
*           id       = zcl_pp_conf=>mc_mess_id
*           number   = '030'
*           severity = if_abap_behv_message=>severity-success
*         )
*       ) TO reported-_header.
*
*    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
*      ENTITY _header
*        ALL FIELDS
*        WITH CORRESPONDING #( keys )
*      RESULT DATA(lt_result).
*
*    result = VALUE #(
*      FOR ls_result IN lt_result
*      (
*        %tky   = ls_result-%tky
*        %param = ls_result
*      )
*    ).
*
*  ENDMETHOD.

  METHOD changeproductionquan.

    DATA lt_update TYPE TABLE FOR UPDATE zpp_i_conf_h.

    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _header
        FIELDS ( material chargequantity productiontype )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_header).

    CHECK lt_header IS NOT INITIAL.

    " Şarj Miktarı
    DATA(ls_header) = VALUE #( lt_header[ 1 ] OPTIONAL ).

    CHECK ls_header-productiontype = zcl_pp_conf=>mc_ut_sarjli.

    DATA(ls_charge) = zcl_pp_conf=>get_charge_quan( iv_material = ls_header-material ).

    CHECK ls_charge IS NOT INITIAL AND ls_charge-sarjmiktari > 0.

    DATA(lv_prodquan) = CONV menge_d( ls_header-chargequantity * ls_charge-sarjmiktari ).


    APPEND VALUE #( %tky = ls_header-%tky
                     productionquantity = CONV #( ls_header-chargequantity * ls_charge-sarjmiktari ) ) TO lt_update.

    MODIFY ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _header
        UPDATE FIELDS ( productionquantity )
        WITH lt_update
      REPORTED DATA(lt_reported).

  ENDMETHOD.

  METHOD setclosingshiftvisibility.

    DATA lt_update TYPE TABLE FOR UPDATE zpp_i_conf_h.

    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _header
        FIELDS ( material productiontype )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_header).

    IF lt_header IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT lt_header ASSIGNING FIELD-SYMBOL(<ls_header>).

      APPEND INITIAL LINE TO lt_update ASSIGNING FIELD-SYMBOL(<ls_update>).

      <ls_update>-%tky = <ls_header>-%tky.

      IF <ls_header>-material IS INITIAL.
        <ls_update>-hideclosingshift = abap_true.
      ELSE.

        DATA(ls_prod_type) = zcl_pp_conf=>get_prod_type( iv_material = <ls_header>-material ).

        <ls_update>-hideclosingshift = COND abap_boolean(
          WHEN ls_prod_type-uretimturu = zcl_pp_conf=>mc_ut_mamul_ee_lahmacun
            OR ls_prod_type-uretimturu = zcl_pp_conf=>mc_ut_ym_ee_lahmacun
            OR ls_prod_type-uretimturu = zcl_pp_conf=>mc_ut_ym_borek
          THEN abap_false
          ELSE abap_true
        ).

      ENDIF.

    ENDLOOP.

    MODIFY ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _header
        UPDATE FIELDS ( hideclosingshift )
        WITH lt_update
      REPORTED DATA(lt_reported).

  ENDMETHOD.

  METHOD validatemandatoryheader.

*    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
*      ENTITY _header
*        FIELDS (
*          shiftcode
*          groupcode
*          material
**          productiontype
**          multiplier
*        )
*        WITH CORRESPONDING #( keys )
*      RESULT DATA(lt_header).



    " Başlık verisini oku
    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _header
        FIELDS (
           shiftcode
          groupcode
          material
        )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_header)
      ENTITY _header BY \_items
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_item).


    LOOP AT lt_header ASSIGNING FIELD-SYMBOL(<ls_header>).

      IF <ls_header>-shiftcode IS INITIAL
      OR <ls_header>-groupcode IS INITIAL
      OR <ls_header>-material  IS INITIAL.

        APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.

        APPEND VALUE #(
          %tky = <ls_header>-%tky

          %element-shiftcode = COND #(
            WHEN <ls_header>-shiftcode IS INITIAL
            THEN if_abap_behv=>mk-on
            ELSE if_abap_behv=>mk-off
          )

          %element-groupcode = COND #(
            WHEN <ls_header>-groupcode IS INITIAL
            THEN if_abap_behv=>mk-on
            ELSE if_abap_behv=>mk-off
          )

          %element-material = COND #(
            WHEN <ls_header>-material IS INITIAL
            THEN if_abap_behv=>mk-on
            ELSE if_abap_behv=>mk-off
          )

          %msg = new_message(
            id       = zcl_pp_conf=>mc_mess_id
            number   = '018'
            severity = if_abap_behv_message=>severity-error
          )
        ) TO reported-_header.

      ENDIF.

*      IF <ls_header>-productiontype = zcl_pp_conf=>mc_ut_ym_borek AND
*         <ls_header>-multiplier IS INITIAL.
*        APPEND VALUE #( %tky = <ls_header>-%tky ) TO failed-_header.
*        APPEND VALUE #(
*          %tky = <ls_header>-%tky
*          %element-multiplier = if_abap_behv=>mk-on
*          %msg = new_message(
*            id       = zcl_pp_conf=>mc_mess_id
*            number   = '037'
*            severity = if_abap_behv_message=>severity-error
*            v1 = <ls_header>-productiontype
*          )
*        ) TO reported-_header.
*
*      ENDIF.

    ENDLOOP.

  ENDMETHOD.

*  METHOD validatemandatoryitems.
*
*    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
*     ENTITY _header
*        ALL FIELDS
*        WITH CORRESPONDING #( keys )
*        RESULT DATA(lt_header)
*      ENTITY _header BY \_items
*        FIELDS (
*          itemuuid
*          confuuid
*          itemno
*          componentmaterial
*          storagelocation
*          batch
*          quantity
*          unit
*          bomitemcat
*          carcount
*        )
*        WITH CORRESPONDING #( keys )
*        RESULT DATA(lt_item).
*
*    LOOP AT lt_header ASSIGNING FIELD-SYMBOL(<ls_header>).
*
*      CHECK lt_item[] IS NOT INITIAL.
*
*      SELECT DISTINCT t~product , t~additional_product FROM zpp_t_addmat AS t
*          INNER JOIN @lt_item AS i ON i~componentmaterial = t~product
*          INTO TABLE @DATA(lt_iskarta).
*
*      SELECT vh~* FROM zpp_i_batch_stock_vh AS vh
*        INNER JOIN @lt_iskarta AS i ON i~additional_product = vh~product
*        INTO TABLE @DATA(lt_stock_i).
*
*      SELECT vh~* FROM zpp_i_batch_stock_vh AS vh
*       INNER JOIN @lt_item AS i ON i~componentmaterial = vh~product
*                               AND i~storagelocation = vh~storagelocation
*      INTO TABLE @DATA(lt_stock).
*
*      LOOP AT lt_item ASSIGNING FIELD-SYMBOL(<ls_item>).
*
*
*      ENDLOOP.
*
*    ENDLOOP.
*
*  ENDMETHOD.

  METHOD setchargequantityvisibility.

    DATA lt_update TYPE TABLE FOR UPDATE zpp_i_conf_h.

    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _header
        FIELDS (
          material
          chargequantity
        )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_header).

    IF lt_header IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT lt_header ASSIGNING FIELD-SYMBOL(<ls_header>).

      APPEND INITIAL LINE TO lt_update ASSIGNING FIELD-SYMBOL(<ls_update>).
      <ls_update>-%tky = <ls_header>-%tky.
      IF <ls_header>-material IS INITIAL.
        <ls_update>-hidechargequantity = abap_true.
        <ls_update>-chargequantity     = 0.
        CONTINUE.
      ENDIF.

      DATA(ls_charge) = zcl_pp_conf=>get_charge_quan( iv_material = <ls_header>-material ).

      " Kural: şarj tablosunda herhangi bir kayıt varsa alan açık.
      IF ls_charge-malzeme IS NOT INITIAL AND ls_charge-sarjmiktari > 0.
        <ls_update>-hidechargequantity = abap_false.
        <ls_update>-chargequantity = <ls_header>-chargequantity.
      ELSE.
        <ls_update>-hidechargequantity = abap_true.
        <ls_update>-chargequantity     = 0.
      ENDIF.

    ENDLOOP.

    MODIFY ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _header
        UPDATE FIELDS (
          hidechargequantity
          chargequantity
        )
        WITH lt_update
      REPORTED DATA(lt_reported).

  ENDMETHOD.

ENDCLASS.





CLASS lhc__item IMPLEMENTATION.

*  METHOD get_instance_authorizations.
*  ENDMETHOD.




  METHOD get_instance_features.

    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE

      ENTITY _item
        FIELDS (
          itemuuid
          confuuid
          itemno
          componentmaterial
          bomitemcat
          isbatchmngmntrequired
          batch
        )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_item)

      ENTITY _item BY \_header
        FIELDS (
          confuuid
          productiontype
          closingshift
          confdoc
        )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_header).

    LOOP AT lt_item ASSIGNING FIELD-SYMBOL(<ls_item>).

      DATA(ls_header) = VALUE #(
        lt_header[
          confuuid = <ls_item>-confuuid
        ] OPTIONAL
      ).

      DATA(lv_is_confirmed) = xsdbool(
        ls_header-confdoc IS NOT INITIAL
      ).

      DATA(lv_item_change_control) = COND #(
        WHEN lv_is_confirmed = abap_true
        THEN if_abap_behv=>fc-o-disabled
        ELSE if_abap_behv=>fc-o-enabled
      ).

*      DATA(lv_car_count_control) = COND #(
*        WHEN lv_is_confirmed = abap_true
*        THEN if_abap_behv=>fc-f-read_only
*
*        WHEN ls_header-productiontype = zcl_pp_conf=>mc_ut_mamul_kurabiye
*         AND <ls_item>-bomitemcat     = zcl_pp_conf=>mc_bomitemcat_z
*        THEN if_abap_behv=>fc-f-unrestricted
*
*        ELSE if_abap_behv=>fc-f-read_only
*      ).
      " Araç Sayısı parti belirlendikten sonra revize edilemesin
      DATA(lv_car_count_control) = COND #(
        WHEN lv_is_confirmed = abap_true
        THEN if_abap_behv=>fc-f-read_only

        WHEN ls_header-productiontype = zcl_pp_conf=>mc_ut_mamul_kurabiye
         AND <ls_item>-bomitemcat     = zcl_pp_conf=>mc_bomitemcat_z
         AND <ls_item>-isbatchmngmntrequired = abap_true
         AND <ls_item>-batch          IS INITIAL
        THEN if_abap_behv=>fc-f-unrestricted

        ELSE if_abap_behv=>fc-f-read_only
      ).




*      DATA(lv_actual_stock_control) = COND #(
*        WHEN lv_is_confirmed = abap_true
*        THEN if_abap_behv=>fc-f-read_only
*
*        WHEN ls_header-closingshift = abap_true
*         AND <ls_item>-bomitemcat = zcl_pp_conf=>mc_bomitemcat_z
*         AND (
*              ls_header-productiontype = zcl_pp_conf=>mc_ut_ym_borek
*           OR ls_header-productiontype = zcl_pp_conf=>mc_ut_mamul_ee_lahmacun
*           OR ls_header-productiontype = zcl_pp_conf=>mc_ut_ym_ee_lahmacun
*         )
*        THEN if_abap_behv=>fc-f-unrestricted
*
*        ELSE if_abap_behv=>fc-f-read_only
*      ).
      DATA(lv_actual_stock_control) = COND #(
      WHEN lv_is_confirmed = abap_true
      THEN if_abap_behv=>fc-f-read_only

      WHEN ls_header-closingshift = abap_true
       AND <ls_item>-bomitemcat = zcl_pp_conf=>mc_bomitemcat_z
       AND (
            ls_header-productiontype = zcl_pp_conf=>mc_ut_ym_borek
         OR ls_header-productiontype = zcl_pp_conf=>mc_ut_mamul_ee_lahmacun
         OR ls_header-productiontype = zcl_pp_conf=>mc_ut_ym_ee_lahmacun
       )
       AND <ls_item>-isbatchmngmntrequired = abap_true
       AND <ls_item>-batch IS INITIAL
      THEN if_abap_behv=>fc-f-unrestricted

      ELSE if_abap_behv=>fc-f-read_only
    ).







      " Parti alanı kuralı:
      " - Teyitli kayıtta kapalı
      " - Sadece parti yönetimli malzemede açık
      " - Boş manuel satırda artık kapalı
      " - Parti ilişkisiz malzemede kapalı
      DATA(lv_batch_control) = COND #(
        WHEN lv_is_confirmed = abap_true
        THEN if_abap_behv=>fc-f-read_only

        WHEN <ls_item>-isbatchmngmntrequired = abap_true
        THEN if_abap_behv=>fc-f-unrestricted

        ELSE if_abap_behv=>fc-f-read_only
      ).

      APPEND VALUE #(
        %tky = <ls_item>-%tky

        %update = lv_item_change_control
        %delete = lv_item_change_control

        %field-carcount            = lv_car_count_control
        %field-actualstockquantity = lv_actual_stock_control
        %field-batch               = lv_batch_control
      ) TO result.

    ENDLOOP.

  ENDMETHOD.


*  METHOD fillcomponentdata.
*
*    DATA lt_update TYPE TABLE FOR UPDATE zpp_i_conf_i.
*
*    IF lcl_buffer=>gv_skip_fillcomponentdata = abap_true.
*      RETURN.
*    ENDIF.
*
*    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
*      ENTITY _item
*        FIELDS (
*          itemuuid
*          confuuid
*          itemno
*          componentmaterial
*          carcount
*          bomitemcat
*          isbatchmngmntrequired
*        )
*        WITH CORRESPONDING #( keys )
*      RESULT DATA(lt_item)
*      ENTITY _item BY \_header
*        FIELDS (
*          confuuid
*          material
*          productiontype
*          confdoc
*        )
*        WITH CORRESPONDING #( keys )
*      RESULT DATA(lt_header).
*
*    " BOM/getmatcomponents ile oluşan satırlar zaten dolu geliyor.
*    " Bu satırlarda tekrar component determination çalışmasın.
*    LOOP AT lt_item ASSIGNING FIELD-SYMBOL(<ls_item>)
*      WHERE itemno IS INITIAL .
*
*
**      IF <ls_item>-itemno IS NOT INITIAL.
**        CONTINUE.
**      ENDIF.
*
*      DATA(ls_header) = VALUE #( lt_header[ confuuid = <ls_item>-confuuid ] OPTIONAL ).
*
*      " ConfDoc doluysa zaten edit kapalı ama teknik olarak da işlem yapma
*      IF ls_header-confdoc IS NOT INITIAL.
*        CONTINUE.
*      ENDIF.
*
*      DATA(lv_mamul) = CONV matnr( |{ ls_header-material ALPHA = IN WIDTH = 18 }| ).
*
*      DATA(lv_yarimamul) = CONV matnr( |{ <ls_item>-componentmaterial ALPHA = IN WIDTH = 18 }| ).
*
*      " Sadece MAMUL_KURABIYE + BOM Item Cat Z için hesapla
*      IF ls_header-productiontype = zcl_pp_conf=>mc_ut_mamul_kurabiye
*      OR <ls_item>-bomitemcat     = zcl_pp_conf=>mc_bomitemcat_z.
*
*        " Araba sayısı boş/0 ise quantity hesaplama
*        IF <ls_item>-carcount IS NOT INITIAL
*        OR <ls_item>-carcount > 0.
*
*          SELECT SINGLE arabakg
*          FROM zpp_t_conf_004
*          WHERE mamul     = @lv_mamul
*            AND yarimamul = @lv_yarimamul
*          INTO @DATA(lv_arac_sayisi).
*          IF sy-subrc <> 0.
*            APPEND VALUE #(
*              %tky = <ls_item>-%tky
*              %msg = new_message(
*                id       = zcl_pp_conf=>mc_mess_id
*                number   = '031'
*                severity = if_abap_behv_message=>severity-error
*                v1       = <ls_item>-componentmaterial
*              )
*            ) TO reported-_item.
*          ENDIF.
*
*        ENDIF.
*
*      ENDIF.
*
*      DATA(lv_product) = |{ <ls_item>-componentmaterial ALPHA = OUT }|.
*      SELECT SINGLE product,
*         productname,
*         baseunit,
*         storageloc,
*         isbatchmanagementrequired FROM zi_product_vh
*     WHERE product = @lv_product
*     INTO @DATA(ls_product).
*      IF sy-subrc EQ 0.
*        "BAŞARILI
*        APPEND VALUE #(
*         %tky     = <ls_item>-%tky
*         quantity = <ls_item>-carcount * lv_arac_sayisi
*         componentdescription = ls_product-productname
*         unit = ls_product-baseunit
*         storagelocation = ls_product-storageloc
*         isbatchmngmntrequired = ls_product-isbatchmanagementrequired ) TO lt_update.
*      ELSE.
*        APPEND VALUE #(
*           %tky = <ls_item>-%tky
*           %msg = new_message(
*             id       = zcl_pp_conf=>mc_mess_id
*             number   = '010'
*             severity = if_abap_behv_message=>severity-error
*             v1        = lv_yarimamul
*           )
*         ) TO reported-_item.
*      ENDIF.
*
*
*    ENDLOOP.
*
*    IF lt_update IS NOT INITIAL.
*
*      MODIFY ENTITIES OF zpp_i_conf_h IN LOCAL MODE
*        ENTITY _item
*          UPDATE FIELDS ( quantity componentdescription unit storagelocation isbatchmngmntrequired )
*          WITH lt_update
*        REPORTED DATA(lt_reported).
*
*    ENDIF.
*  ENDMETHOD.

  METHOD fillcomponentdata.

    DATA lt_update TYPE TABLE FOR UPDATE zpp_i_conf_i.

    IF lcl_buffer=>gv_skip_fillcomponentdata = abap_true.
      RETURN.
    ENDIF.

    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _item
        FIELDS (
          itemuuid
          confuuid
          itemno
          componentmaterial
          componentdescription
          storagelocation
          batch
          quantity
          unit
          carcount
          actualstockquantity
          bomitemcat
          isbatchmngmntrequired
        )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_item)

      ENTITY _item BY \_header
        FIELDS (
          confuuid
          material
          productiontype
          confdoc
        )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_header).

    LOOP AT lt_item ASSIGNING FIELD-SYMBOL(<ls_item>).

      DATA(ls_header) = VALUE #( lt_header[ confuuid = <ls_item>-confuuid ] OPTIONAL ).

      IF ls_header-confdoc IS NOT INITIAL.
        CONTINUE.
      ENDIF.

      IF <ls_item>-componentmaterial IS INITIAL.

        APPEND VALUE #(
          %tky = <ls_item>-%tky

          componentdescription   = ''
          storagelocation        = ''
          unit                   = ''
          batch                  = ''
          bomitemcat             = ''
          isbatchmngmntrequired  = abap_false
        ) TO lt_update.

        CONTINUE.

      ENDIF.

      " Bu conversionlar senin mevcut halinle bırakıldı
      DATA(lv_yarimamul) = CONV matnr( |{ <ls_item>-componentmaterial ALPHA = IN WIDTH = 18 }| ).
      DATA(lv_product)   = |{ <ls_item>-componentmaterial ALPHA = OUT }|.

      SELECT SINGLE product,
                    productname,
                    baseunit,
                    storageloc,
                    isbatchmanagementrequired
        FROM zi_product_vh
        WHERE product = @lv_product
        INTO @DATA(ls_product).

      IF sy-subrc <> 0.

        APPEND VALUE #(
          %tky = <ls_item>-%tky
          %msg = new_message(
            id       = zcl_pp_conf=>mc_mess_id
            number   = '010'
            severity = if_abap_behv_message=>severity-error
            v1       = |{ <ls_item>-componentmaterial ALPHA = OUT }|
          )
        ) TO reported-_item.

        CONTINUE.

      ENDIF.

      " Kalem Tipi
      DATA(lv_bomitemcat) = zcl_pp_conf=>get_bom_item_cat( iv_material  = ls_header-material iv_component = <ls_item>-componentmaterial ).

*      DATA(lt_bom_result) = zcl_pp_conf=>explode_bom( iv_material = lv_product iv_quantity = lv_quantity ).
*      IF lt_bom_result IS INITIAL.
*        RETURN.
*      ENDIF.

      DATA(lv_new_quantity) = <ls_item>-quantity.
      DATA(lv_new_storage_location) = ls_product-storageloc.

      IF lv_new_storage_location IS INITIAL.
        lv_new_storage_location = <ls_item>-storagelocation.
      ENDIF.

      " Sadece MAMUL_KURABIYE + yeni BOM Item Cat Z için CarCount'a bağlı hesap.
      " Burada eski <ls_item>-bomitemcat değil, yeni lv_new_bomitemcat kullanılıyor.
      IF ls_header-productiontype = zcl_pp_conf=>mc_ut_mamul_kurabiye
     AND lv_bomitemcat       = zcl_pp_conf=>mc_bomitemcat_z
     AND <ls_item>-carcount      IS NOT INITIAL
     AND <ls_item>-carcount      > 0.

        DATA(lv_mamul) = CONV matnr( |{ ls_header-material ALPHA = IN WIDTH = 18 }| ).

        SELECT SINGLE arabakg
          FROM zpp_t_conf_004
          WHERE mamul     = @lv_mamul
            AND yarimamul = @lv_yarimamul
          INTO @DATA(lv_arabakg).

        IF sy-subrc <> 0.

          APPEND VALUE #(
            %tky = <ls_item>-%tky
            %element-carcount = if_abap_behv=>mk-on
            %msg = new_message(
              id       = zcl_pp_conf=>mc_mess_id
              number   = '031'
              severity = if_abap_behv_message=>severity-error
              v1       = |{ <ls_item>-componentmaterial ALPHA = OUT }|
            )
          ) TO reported-_item.

        ELSEIF lv_arabakg IS INITIAL.

          APPEND VALUE #(
            %tky = <ls_item>-%tky
            %element-carcount = if_abap_behv=>mk-on
            %msg = new_message(
              id       = zcl_pp_conf=>mc_mess_id
              number   = '032'
              severity = if_abap_behv_message=>severity-error
              v1       = |{ <ls_item>-componentmaterial ALPHA = OUT }|
            )
          ) TO reported-_item.

        ELSE.

          SELECT SINGLE SUM( stockqty )
            FROM zpp_i_batch_stock_vh
            WHERE product         = @lv_yarimamul
              AND storagelocation = @lv_new_storage_location
            INTO @DATA(lv_total_stock_raw).

          DATA(lv_total_stock) = CONV zpp_i_conf_i-quantity( lv_total_stock_raw ).
          DATA(lv_used_quantity) = CONV zpp_i_conf_i-quantity( <ls_item>-carcount * lv_arabakg ).

          lv_new_quantity = CONV zpp_i_conf_i-quantity(
            lv_total_stock - lv_used_quantity
          ).

          IF lv_new_quantity < 0.

            APPEND VALUE #(
              %tky = <ls_item>-%tky
              %element-carcount = if_abap_behv=>mk-on
              %msg = new_message(
                id       = zcl_pp_conf=>mc_mess_id
                number   = '033'
                severity = if_abap_behv_message=>severity-error
                v1       = |{ <ls_item>-componentmaterial ALPHA = OUT }|
                v2       = |{ lv_new_quantity }|
              )
            ) TO reported-_item.

            CONTINUE.

          ENDIF.

        ENDIF.

      ENDIF.

      DATA(lv_new_batch) = COND zpp_i_conf_i-batch(
        WHEN ls_product-isbatchmanagementrequired = abap_true
        THEN <ls_item>-batch
        ELSE ''
      ).

      IF <ls_item>-componentdescription  <> ls_product-productname
      OR <ls_item>-storagelocation       <> lv_new_storage_location
      OR <ls_item>-unit                  <> ls_product-baseunit
      OR <ls_item>-quantity              <> lv_new_quantity
      OR <ls_item>-bomitemcat            <> lv_bomitemcat
      OR <ls_item>-isbatchmngmntrequired <> ls_product-isbatchmanagementrequired
      OR <ls_item>-batch                 <> lv_new_batch.

        APPEND VALUE #(
          %tky = <ls_item>-%tky

          componentdescription   = ls_product-productname
          storagelocation        = lv_new_storage_location
          unit                   = ls_product-baseunit
          quantity               = lv_new_quantity
          bomitemcat             = lv_bomitemcat
          isbatchmngmntrequired  = ls_product-isbatchmanagementrequired
          batch                  = lv_new_batch
        ) TO lt_update.

      ENDIF.

    ENDLOOP.

    IF lt_update IS NOT INITIAL.

      MODIFY ENTITIES OF zpp_i_conf_h IN LOCAL MODE
        ENTITY _item
          UPDATE FIELDS (
            componentdescription
            storagelocation
            unit
            quantity
            bomitemcat
            isbatchmngmntrequired
            batch
          )
          WITH lt_update
        REPORTED DATA(lt_reported).

    ENDIF.

  ENDMETHOD.







  METHOD changequantitybycarcount.

    DATA: lt_update    TYPE TABLE FOR UPDATE zpp_i_conf_i.

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Determination normal kullanımda tek item için çalışacak kabulü
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _item
        FIELDS (
          itemuuid
          confuuid
          componentmaterial
          storagelocation
          carcount
          quantity
          bomitemcat
        )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item)

      ENTITY _item BY \_header
        FIELDS (
          confuuid
          material
          productiontype
          confdoc
        )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_header).

    READ TABLE lt_item ASSIGNING FIELD-SYMBOL(<ls_item>) INDEX 1.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    DATA(ls_header) = VALUE #( lt_header[ confuuid = <ls_item>-confuuid ] OPTIONAL ).


    IF ls_header-productiontype <> zcl_pp_conf=>mc_ut_mamul_kurabiye.
      RETURN.
    ENDIF.
    IF <ls_item>-bomitemcat <> zcl_pp_conf=>mc_bomitemcat_z.
      RETURN.
    ENDIF.

    IF ls_header-material IS INITIAL
    OR <ls_item>-componentmaterial IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_mamul) = CONV matnr( |{ ls_header-material ALPHA = IN WIDTH = 18 }| ).

    DATA(lv_yarimamul) = CONV matnr( |{ <ls_item>-componentmaterial ALPHA = IN WIDTH = 18 }| ).


    SELECT SINGLE arabakg
      FROM zpp_t_conf_004
      WHERE mamul     = @lv_mamul
        AND yarimamul = @lv_yarimamul
      INTO @DATA(lv_arabakg).
    IF sy-subrc <> 0.
      APPEND VALUE #(  %tky = <ls_item>-%tky  %element-carcount = if_abap_behv=>mk-on
        %msg = new_message( id = zcl_pp_conf=>mc_mess_id  number = '031' severity = if_abap_behv_message=>severity-error
          v1       = |{ <ls_item>-componentmaterial ALPHA = OUT }| ) ) TO reported-_item.
      RETURN.
    ENDIF.

    IF lv_arabakg IS INITIAL.
      APPEND VALUE #( %tky = <ls_item>-%tky %element-carcount = if_abap_behv=>mk-on
        %msg = new_message( id = zcl_pp_conf=>mc_mess_id  number = '032' severity = if_abap_behv_message=>severity-error
          v1 = |{ <ls_item>-componentmaterial ALPHA = OUT }| ) ) TO reported-_item.
      RETURN.
    ENDIF.


    SELECT SINGLE SUM( stockqty )
      FROM zpp_i_batch_stock_vh
      WHERE product = @lv_yarimamul
        AND storagelocation = @<ls_item>-storagelocation
      INTO @DATA(lv_total_stock_raw).

    DATA(lv_total_stock) = CONV zpp_i_conf_i-quantity( lv_total_stock_raw ).

    DATA(lv_used_quantity) = CONV zpp_i_conf_i-quantity( <ls_item>-carcount * lv_arabakg ).

    DATA(lv_new_quantity) = CONV zpp_i_conf_i-quantity( lv_total_stock - lv_used_quantity ).

    IF lv_new_quantity < 0.
      APPEND VALUE #(
        %tky = <ls_item>-%tky %element-carcount = if_abap_behv=>mk-on
        %msg = new_message(
          id       = zcl_pp_conf=>mc_mess_id
          number   = '033'
          severity = if_abap_behv_message=>severity-error
          v1       = |{ <ls_item>-componentmaterial ALPHA = OUT }|
          v2       = |{ lv_new_quantity }|
        )
      ) TO reported-_item.

      RETURN.

    ENDIF.

    IF lv_new_quantity = <ls_item>-quantity.
      RETURN.
    ENDIF.

    APPEND VALUE #(
      %tky     = <ls_item>-%tky
      quantity = lv_new_quantity
    ) TO lt_update.

    MODIFY ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _item
        UPDATE FIELDS ( quantity )
        WITH lt_update
      REPORTED DATA(lt_reported).

  ENDMETHOD.

  METHOD changequantitybyactualstock.


    DATA lt_update TYPE TABLE FOR UPDATE zpp_i_conf_i.

    READ ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _item
        FIELDS (
          itemuuid
          confuuid
          componentmaterial
          storagelocation
          quantity
          actualstockquantity
          bomitemcat
        )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_item)

      ENTITY _item BY \_header
        FIELDS (
          confuuid
          productiontype
          closingshift
          confdoc
        )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_header).

    READ TABLE lt_item ASSIGNING FIELD-SYMBOL(<ls_item>) INDEX 1.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    DATA(ls_header) = VALUE #( lt_header[ confuuid = <ls_item>-confuuid ] OPTIONAL ).
    CHECK ls_header-closingshift = abap_true AND
          <ls_item>-bomitemcat = zcl_pp_conf=>mc_bomitemcat_z AND
         ( ls_header-productiontype = zcl_pp_conf=>mc_ut_ym_borek OR
           ls_header-productiontype = zcl_pp_conf=>mc_ut_mamul_ee_lahmacun OR
           ls_header-productiontype = zcl_pp_conf=>mc_ut_ym_ee_lahmacun ).

    IF <ls_item>-componentmaterial IS INITIAL
    OR <ls_item>-storagelocation IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_component) = CONV matnr( |{ <ls_item>-componentmaterial ALPHA = IN WIDTH = 18 }| ).

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Bileşen + Depo Yeri bazında toplam stok
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    SELECT SUM( stockqty )
      FROM zpp_i_batch_stock_vh
      WHERE product         = @lv_component
        AND storagelocation = @<ls_item>-storagelocation
      INTO @DATA(lv_total_stock_raw).

    DATA(lv_total_stock) = CONV zpp_i_conf_i-quantity( lv_total_stock_raw ).

    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Son vardiya seçiliyse:
    " Quantity = Toplam Stok - Fiili Stok Miktarı
    """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    DATA(lv_new_quantity) = CONV zpp_i_conf_i-quantity( lv_total_stock - <ls_item>-actualstockquantity ).

    IF lv_new_quantity < 0.

      APPEND VALUE #(
        %tky = <ls_item>-%tky
        %element-actualstockquantity = if_abap_behv=>mk-on
        %msg = new_message(
          id       = zcl_pp_conf=>mc_mess_id
          number   = '033'
          severity = if_abap_behv_message=>severity-error
          v1       = |{ <ls_item>-componentmaterial ALPHA = OUT }|
          v2       = |{ lv_new_quantity }|
        )
      ) TO reported-_item.

      RETURN.

    ENDIF.

    IF lv_new_quantity = <ls_item>-quantity.
      RETURN.
    ENDIF.

    APPEND VALUE #(  %tky     = <ls_item>-%tky   quantity = lv_new_quantity  ) TO lt_update.

    MODIFY ENTITIES OF zpp_i_conf_h IN LOCAL MODE
      ENTITY _item
        UPDATE FIELDS ( quantity )
        WITH lt_update
      REPORTED DATA(lt_reported).


  ENDMETHOD.





ENDCLASS.
