<?php
namespace app\command;

use think\console\Command;
use think\console\Input;
use think\console\Output;

class PetRemind extends Command
{
    protected function configure()
    {
        $this->setName('pet:remind')->setDescription('发送到期养护提醒；建议每分钟执行');
    }

    protected function execute(Input $input, Output $output)
    {
        $output->writeln('处理提醒：' . (new \app\common\service\ReminderService())->dispatch());
        return 0;
    }
}
