

while(1)
{
system(" ./sipp -sf record_atom_mp3_caller.xml -p 7078 -mp 19400 172.24.131.27:5070 -slave s1 -slave_cfg basic_3pcc_hf.cfg");
sleep(60);
}
