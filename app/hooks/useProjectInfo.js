import { useEffect, useState } from 'react';
import useFirebaseRealtime from './useFirebaseRealtime';

const useProjectInfo = () => {
  const { data: projectInfo, loading, error } = useFirebaseRealtime('projectInfo');
  const { data: projectName, loading: nameLoading, error: nameError } = useFirebaseRealtime('projectname');
  
  const [processedInfo, setProcessedInfo] = useState({
    projectName: 'CantRead', // Default value
    moduleRegister: 0,
    zoneRegister: 0,
    usageBilling: ''
  });

  useEffect(() => {
    if (projectInfo || projectName) {
      setProcessedInfo({
        projectName: projectName || projectInfo?.name || 'Gedung Atria',
        moduleRegister: projectInfo?.moduleRegister || 63,
        zoneRegister: projectInfo?.zoneRegister || 315,
        usageBilling: projectInfo?.usageBilling || ''
      });
    }
  }, [projectInfo, projectName]);

  return { 
    projectInfo: processedInfo, 
    loading: loading || nameLoading, 
    error: error || nameError 
  };
};

export default useProjectInfo;