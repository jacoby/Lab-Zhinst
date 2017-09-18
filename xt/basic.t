#!perl -T
use warnings;
use strict;

use Test::More;

BEGIN { use_ok('Lab::Zhinst') };

my ($rv, $conn) = Lab::Zhinst->Init();
is($rv, 0, "Init retval");
isa_ok($conn, 'Lab::Zhinst');

($rv) = $conn->Connect('localhost', 8004);
is($rv, 0, "Connect retval");


($rv, my $implementations) = ziAPIListImplementations();
is($rv, 0, "ListImplementations retval");
is($implementations, "ziAPI_Core\nziAPI_AsyncSocket\nziAPI_ziServer1",
    "ListImplementations");

($rv, my $api_level) = $conn->GetConnectionAPILevel();
is($rv, 0, "GetConnectionAPILevel retval");
is($api_level, 1, "GetConnectionAPILevel");

my $buffer_size = 100000;
($rv, my $nodes) = $conn->ListNodes("/", $buffer_size,
                                    ZI_LIST_NODES_ABSOLUTE | ZI_LIST_NODES_RECURSIVE);
is($rv, 0, "ListNodes retval");
like($nodes, qr{/zi/about/version}i, "ListNodes");

for my $getter (qw/GetValueD GetValueI/) {
    my ($rv, $value) = $conn->$getter('/zi/config/port');
    is($rv, 0, "$getter retval");
    is($value, 8004, "$getter");
}

($rv, my $value_b) = $conn->GetValueB('/zi/about/copyright', 100);
is($rv, 0, "GetValueB retval");
like($value_b, qr/Zurich Instruments/, "GetValueB");


($rv, my $error_string) = ziAPIGetError(ZI_ERROR_LENGTH);
is($rv, 0, "ziAPIGetError retval");
is($error_string, "Provided Buffer is too small", "ziAPIGetError");



#
# Data Streaming
#
{
    my $event = ziAPIAllocateEventEx();
    isa_ok($event, "Lab::Zhinst::ZIEvent");
    my $path = '/zi/config/port';
    my ($rv) = $conn->Subscribe($path);
    is($rv, 0, "Subscribe retval");
    
    ($rv) = $conn->GetValueAsPollData($path);
    is($rv, 0, "GetValueAsPollData retval");

    ($rv) = $conn->GetValueAsPollData($path);
    is($rv, 0, "GetValueAsPollData retval");
    

    my ($rv, $data) = $conn->PollDataEx($event, 1000);
    is($rv, 0, "PollDataEx retval");

    is_deeply($data, {
        valueType => ZI_VALUE_TYPE_INTEGER_DATA,
        count => 2,
        path => $path,
        values => [8004, 8004]
              }, "Integer event");
        

    ($rv) = $conn->UnSubscribe($path);
    is($rv, 0, "UnSubscribe retval");
}



($rv) = $conn->Disconnect();
is($rv, 0, "Disconnect retval");
done_testing();
