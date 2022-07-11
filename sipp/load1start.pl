

while(1)
{
sleep(10);
system("./sipp -sf record_atom_mp3_agent.xml -p 23235 -mp 16300 172.24.131.36:5070 -master m -slave_cfg basic_3pcc.cfg -m 1");
sleep(50);
}


