@EndUserText.label: 'Teyit Duruş Sebebi'
define abstract entity ZPP_A_DWNTM_REASON
{
  @EndUserText.label: 'İş Yeri'
  @Consumption.valueHelpDefinition: [
    {
      entity: {
        name: 'ZPP_I_WORKCENTER_VH',
        element: 'WorkCenter'
      }
    }
  ]
  WorkCenter : arbpl;

  @EndUserText.label: 'Duruş Kodu'
  @Consumption.valueHelpDefinition: [
    {
      entity: {
        name: 'ZPP_I_DWNTM_REASON_VH',
        element: 'DowntimeCode'
      }
    }
  ]
  DowntimeCode : abap.numc(2);

  @EndUserText.label: 'Durma Süresi'
  DowntimeDuration : abap.int4;
}
