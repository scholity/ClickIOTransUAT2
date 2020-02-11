global class CreateTrainingRevenueSchedule implements Schedulable
{
    global void execute (SchedulableContext SC)
    {
        CreateTrainingRevenueBatch trBatch = new  CreateTrainingRevenueBatch();
        database.executeBatch(trBatch,100);
    }
}