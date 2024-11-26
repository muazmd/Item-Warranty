reportextension 70101 "Sales Order Confirmation" extends "Standard Sales - Order Conf."
{
    dataset
    {
        add(Header)
        {
            column(WarrantyLaborlbl; WarrantyLaborlbl) { }
            column(WarrantyPartslbl; WarrantyPartslbl) { }
        }
        add(Line)
        {
            column(Warranty_End_Date_Labor; "Warranty End Date Labor") { }
            column(Warranty_End_Date_parts; "Warranty End Date parts") { }
        }
    }

  

    rendering
    {
        layout("Sales Order Confirmation")
        {
            Type = RDLC;
            LayoutFile = 'src/Layouts/StandardSalesOrderConf.rdl';
        }
    }
    var
        WarrantyLaborlbl: label 'Labor Warranty';
        WarrantyPartslbl: Label 'Parts Warranty';
}