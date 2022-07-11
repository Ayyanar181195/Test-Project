

while(1)
{
system(" ./sipp -sf record_atom_mp3_caller.xml -p 9078 -mp 17400 172.24.131.36:5070 -slave s1 -slave_cfg basic_3pcc.cfg");
sleep(60);
}

