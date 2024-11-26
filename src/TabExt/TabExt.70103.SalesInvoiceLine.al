tableextension 70103 "Sales Invoice Line" extends "Sales Invoice Line"
{
    fields
    {
        field(70100; "B2C Warranty Duration Labor"; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(70101; "B2C Warranty Duration Parts"; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(70102; "B2B Warranty Duration Labor"; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(70103; "B2B Warranty Duration Parts"; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(70104; "Warranty End Date Labor"; date)
        {
            DataClassification = ToBeClassified;
        }
        field(70105; "Warranty End Date parts"; date)
        {
            DataClassification = ToBeClassified;
        }
    }

}