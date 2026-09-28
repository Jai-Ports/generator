#import "Basic";
Xml :: #import "pugixml";

main :: () {
    Xml.initialize_program();
    document: Xml.Xml_Document;
    Xml.init(*document);
    defer Xml.deinit(*document);
    parsed: Xml.Xml_Parse_Result;
    source := "<root><item n='17'>Jai &amp; XML</item><item n='25'>&#9731;</item></root>";
    Xml.load_string(*parsed, *document, cast(*s8) temp_c_string(source), Xml.PARSE_DEFAULT);
    assert(parsed.status == Xml.STATUS_OK);
    root := Xml.document_element(*document);
    item := Xml.child(*root, cast(*s8) temp_c_string("item"));
    attribute := Xml.attribute(*item, cast(*s8) temp_c_string("n"));
    assert(Xml.as_int(*attribute, -1) == 17);
    assert(to_string(cast(*u8) Xml.child_value(*item)) == "Jai & XML");

    query: Xml.Xpath_Query;
    Xml.init(*query, cast(*s8) temp_c_string("sum(/root/item/@n)"), null);
    defer Xml.deinit(*query);
    query_node: Xml.Xpath_Node;
    Xml.init(*query_node, *document.xml_node);
    assert(Xml.evaluate_number(*query, *query_node) == 42.0);

    Xml.load_string(*parsed, *document, cast(*s8) temp_c_string("<root><broken></root>"), Xml.PARSE_DEFAULT);
    assert(parsed.status != Xml.STATUS_OK);
    print("pugixml DOM/XPath/error verification passed\n");
}
