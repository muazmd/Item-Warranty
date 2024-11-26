pageextension 70101 "Item" extends "Item Card"
{
    layout
    {
        addlast(Item)
        {
            field("B2C Warranty Duration Labor"; Rec."B2C Warranty Duration Labor")
            {
                ApplicationArea = all;
            }
            field("B2C Warranty Duration Parts"; Rec."B2C Warranty Duration Parts")
            {
                ApplicationArea = all;
            }
            field("B2B Warranty Duration Labor"; Rec."B2B Warranty Duration Labor")
            {
                ApplicationArea = all;
            }
            field("B2B Warranty Duration Parts"; Rec."B2B Warranty Duration Parts")
            {
                ApplicationArea = all;
            }
        }
    }

}