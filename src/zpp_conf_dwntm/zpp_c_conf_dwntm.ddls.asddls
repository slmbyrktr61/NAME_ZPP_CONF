@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@EndUserText: {
  label: 'Duruş Verisi Düzenle'
}
@ObjectModel: {
  sapObjectNodeType.name: 'ZPP_CONF_DWNTM'
}
@AccessControl.authorizationCheck: #MANDATORY
define root view entity ZPP_C_CONF_DWNTM
  provider contract transactional_query
  as projection on ZPP_I_CONF_DWNTM
  association [1..1] to ZPP_I_CONF_DWNTM as _BaseEntity on  $projection.DowntimeUUID = _BaseEntity.DowntimeUUID
                                                        and $projection.Shiftcode    = _BaseEntity.Shiftcode
                                                        and $projection.Groupcode    = _BaseEntity.Groupcode
                                                        and $projection.Workcenter   = _BaseEntity.Workcenter
                                                        and $projection.Material     = _BaseEntity.Material
                                                        and $projection.DowntimeDate = _BaseEntity.DowntimeDate
                                                        and $projection.DowntimeTime = _BaseEntity.DowntimeTime
{
  key DowntimeUUID,
      Shiftcode,
      Groupcode,
      Workcenter,
      WorkCenterText,
      Material,
      MaterialDescription,
      DowntimeDate,
      DowntimeTime,
      Shift,
      DowntimeCode,
      DowntimeCodeDescription,
      DowntimeDuration,
        @UI.multiLineText: true
      DowntimeText,
      @Semantics: {
        user.createdBy: true
      }
      CreatedBy,
      @Semantics: {
        systemDateTime.createdAt: true
      }
      CreatedAt,
      @Semantics: {
        user.localInstanceLastChangedBy: true
      }
      LastChangedBy,
      @Semantics: {
        systemDateTime.localInstanceLastChangedAt: true
      }
      LastChangedAt,
      @Semantics: {
        systemDateTime.lastChangedAt: true
      }
      LocalLastChangedAt,
      _BaseEntity
}
