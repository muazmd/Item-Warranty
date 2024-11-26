pageextension 70102 "Sales Order Subform" extends "Sales Order Subform"
{
    layout
    {
        addafter("Shipment Date")
        {
            field("Warranty End Date Labor"; Rec."Warranty End Date Labor")
            {
                ApplicationArea = all;
                Editable = false;

            }
            field("Warranty End Date parts"; Rec."Warranty End Date parts")
            {
                ApplicationArea = all;
                Editable = false;
            }
        }
    }

    actions
    {
        addfirst("F&unctions")
        {
            action("Select Extended Warranty")
            {
                ApplicationArea = all;
                Image = Add;
                trigger OnAction()
                var
                    WarantyMgt: Codeunit "Item Warranty Mgt.";
                begin
                    WarantyMgt.SelectExtendedWarranty(rec);
                end;
            }
        }
    }

    var
}