

while(1)
{
sleep(10);
system("./sipp -sf record_atom_mp3_agent.xml -p 12235 -mp 19300 172.24.131.27:5070 -master m -slave_cfg basic_3pcc_hf.cfg -m 1");
sleep(50);
}


